from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from sqlalchemy.orm import Session

from .config import settings
from .database import get_db
from .models import Topic
from .schemas import AuthSessionResponse, BootstrapResponse, EventAttachRequest, FollowCreateRequest, FollowUpdateRequest, HealthResponse, HistoryCreateRequest, HistoryItem, MessageResponse, PreferenceUpdateRequest, RecommendationListResponse, ShareCreateRequest, ShareCreateResponse, ShareOpenResponse, SmsSendRequest, SmsSendResponse, SmsVerifyRequest, TimelineResponse, TopicCreateRequest, TopicFollowPayload, TopicSummary, UserPreferencePayload, UserProfile
from .services import attach_event_to_topic, bootstrap_payload, build_timeline_response, create_share, create_user_topic, ensure_topic_access, ensure_topic_owner, follow_topic, get_current_user, hot_topics, list_follows, list_history, list_topics, open_share, random_topics, record_topic_view, require_auth_token, revoke_session, send_sms_challenge, topic_summary_from_model, unfollow_topic, update_follow, verify_sms_login

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    return HealthResponse(status="ok", app_name=settings.app_name, environment=settings.environment)


@router.post("/v1/auth/sms/send", response_model=SmsSendResponse)
def send_sms(request: SmsSendRequest, http_request: Request, db: Session = Depends(get_db)) -> SmsSendResponse:
    challenge, debug_code = send_sms_challenge(
        db,
        phone_number=request.phone_number,
        purpose=request.purpose,
        request_ip=http_request.client.host if http_request.client else None,
    )
    return SmsSendResponse(
        challenge_id=challenge.id,
        expires_in_seconds=settings.sms_code_ttl_seconds,
        debug_code=debug_code,
    )


@router.post("/v1/auth/sms/verify", response_model=AuthSessionResponse)
def verify_sms(request: SmsVerifyRequest, http_request: Request, db: Session = Depends(get_db)) -> AuthSessionResponse:
    access_token, session, user = verify_sms_login(
        db,
        challenge_id=request.challenge_id,
        phone_number=request.phone_number,
        code=request.code,
        device_id=request.device_id,
        device_name=request.device_name,
        client_platform=request.client_platform,
        app_version=request.app_version,
        ip_address=http_request.client.host if http_request.client else None,
    )
    return AuthSessionResponse(
        access_token=access_token,
        expires_at=session.expires_at,
        user=UserProfile.model_validate(user),
        preferences=UserPreferencePayload.model_validate(user.preferences),
    )


@router.post("/v1/auth/logout", response_model=MessageResponse)
def logout(token: str = Depends(require_auth_token), db: Session = Depends(get_db)) -> MessageResponse:
    _, session = get_current_user(db, token)
    revoke_session(db, session)
    return MessageResponse(message="logged out")


@router.get("/v1/bootstrap", response_model=BootstrapResponse)
def bootstrap(token: str = Depends(require_auth_token), db: Session = Depends(get_db)) -> BootstrapResponse:
    user, _ = get_current_user(db, token)
    follows, history, hot = bootstrap_payload(db, user)
    return BootstrapResponse(
        user=UserProfile.model_validate(user),
        preferences=UserPreferencePayload.model_validate(user.preferences),
        follows=follows,
        history=history,
        hot_topics=hot,
    )


@router.get("/v1/me", response_model=UserProfile)
def me(token: str = Depends(require_auth_token), db: Session = Depends(get_db)) -> UserProfile:
    user, _ = get_current_user(db, token)
    return UserProfile.model_validate(user)


@router.patch("/v1/me/preferences", response_model=UserPreferencePayload)
def update_preferences(
    payload: PreferenceUpdateRequest,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> UserPreferencePayload:
    user, _ = get_current_user(db, token)
    preference = user.preferences
    if payload.default_sort_order is not None:
        preference.default_sort_order = payload.default_sort_order
    if payload.selected_topic_id is not None:
        topic = db.get(Topic, payload.selected_topic_id)
        ensure_topic_access(topic, user)
        preference.selected_topic_id = payload.selected_topic_id
    if payload.home_recommendation_mode is not None:
        preference.home_recommendation_mode = payload.home_recommendation_mode
    db.commit()
    db.refresh(preference)
    return UserPreferencePayload.model_validate(preference)


@router.get("/v1/me/follows", response_model=list[TopicFollowPayload])
def get_follows(token: str = Depends(require_auth_token), db: Session = Depends(get_db)) -> list[TopicFollowPayload]:
    user, _ = get_current_user(db, token)
    return [
        TopicFollowPayload(
            topic=TopicSummary.model_validate(follow.topic),
            is_pinned=follow.is_pinned,
            pin_rank=follow.pin_rank,
            custom_sort_rank=follow.custom_sort_rank,
            notification_level=follow.notification_level,
            followed_at=follow.followed_at,
        )
        for follow in list_follows(db, user)
    ]


@router.post("/v1/me/follows", response_model=TopicFollowPayload)
def create_follow(
    payload: FollowCreateRequest,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> TopicFollowPayload:
    user, _ = get_current_user(db, token)
    topic = ensure_topic_access(db.get(Topic, payload.topic_id), user)
    follow = follow_topic(db, user, topic)
    db.refresh(follow)
    db.refresh(topic)
    return TopicFollowPayload(
        topic=TopicSummary.model_validate(topic),
        is_pinned=follow.is_pinned,
        pin_rank=follow.pin_rank,
        custom_sort_rank=follow.custom_sort_rank,
        notification_level=follow.notification_level,
        followed_at=follow.followed_at,
    )


@router.patch("/v1/me/follows/{topic_id}", response_model=TopicFollowPayload)
def patch_follow(
    topic_id: str,
    payload: FollowUpdateRequest,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> TopicFollowPayload:
    user, _ = get_current_user(db, token)
    topic = ensure_topic_access(db.get(Topic, topic_id), user)
    follow = update_follow(
        db,
        user,
        topic,
        is_pinned=payload.is_pinned,
        pin_rank=payload.pin_rank,
        custom_sort_rank=payload.custom_sort_rank,
        notification_level=payload.notification_level,
    )
    return TopicFollowPayload(
        topic=TopicSummary.model_validate(topic),
        is_pinned=follow.is_pinned,
        pin_rank=follow.pin_rank,
        custom_sort_rank=follow.custom_sort_rank,
        notification_level=follow.notification_level,
        followed_at=follow.followed_at,
    )


@router.delete("/v1/me/follows/{topic_id}", response_model=MessageResponse)
def delete_follow(
    topic_id: str,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> MessageResponse:
    user, _ = get_current_user(db, token)
    topic = ensure_topic_access(db.get(Topic, topic_id), user)
    unfollow_topic(db, user, topic)
    return MessageResponse(message="unfollowed")


@router.get("/v1/me/history", response_model=list[HistoryItem])
def get_history(
    limit: int = Query(default=20, ge=1, le=100),
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> list[HistoryItem]:
    user, _ = get_current_user(db, token)
    return list_history(db, user, limit=limit)


@router.post("/v1/me/history", response_model=MessageResponse)
def create_history(
    payload: HistoryCreateRequest,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> MessageResponse:
    user, _ = get_current_user(db, token)
    record_topic_view(
        db,
        user,
        topic_id=payload.topic_id,
        event_node_id=payload.event_node_id,
        opened_from=payload.opened_from,
    )
    return MessageResponse(message="history recorded")


@router.get("/v1/topics", response_model=list[TopicSummary])
def get_topics(
    scope: str = Query(default="discover"),
    search: str | None = Query(default=None),
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> list[TopicSummary]:
    user = None
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ", 1)[1].strip()
        user, _ = get_current_user(db, token)
    return [topic_summary_from_model(topic) for topic in list_topics(db, user=user, scope=scope, search=search)]


@router.post("/v1/topics", response_model=TopicSummary)
def create_topic(
    payload: TopicCreateRequest,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> TopicSummary:
    user, _ = get_current_user(db, token)
    topic = create_user_topic(
        db,
        user,
        title=payload.title,
        tagline=payload.tagline,
        description=payload.description,
        core_keywords=payload.core_keywords,
        related_keywords=payload.related_keywords,
        excluded_keywords=payload.excluded_keywords,
        start_time_at=payload.start_time_at,
        start_time_precision=payload.start_time_precision,
        start_time_label=payload.start_time_label,
        visibility=payload.visibility,
        share_enabled=payload.share_enabled,
        seed_events=payload.seed_events,
    )
    return TopicSummary.model_validate(topic)


@router.get("/v1/topics/{topic_id}", response_model=TopicSummary)
def get_topic(
    topic_id: str,
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> TopicSummary:
    user = None
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ", 1)[1].strip()
        user, _ = get_current_user(db, token)
    topic = ensure_topic_access(db.get(Topic, topic_id), user)
    return TopicSummary.model_validate(topic)


@router.get("/v1/topics/{topic_id}/timeline", response_model=TimelineResponse)
def get_timeline(
    topic_id: str,
    granularity: str | None = Query(default="auto"),
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> TimelineResponse:
    user = None
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ", 1)[1].strip()
        user, _ = get_current_user(db, token)
    topic = ensure_topic_access(db.get(Topic, topic_id), user)
    return build_timeline_response(db, topic, granularity=granularity)


@router.post("/v1/topics/{topic_id}/events", response_model=TimelineResponse)
def add_event_to_topic(
    topic_id: str,
    payload: EventAttachRequest,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> TimelineResponse:
    user, _ = get_current_user(db, token)
    topic = ensure_topic_access(db.get(Topic, topic_id), user)
    if topic.kind.value != "user_created":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="standard topic writes should go through admin pipeline",
        )
    ensure_topic_owner(topic, user)
    attach_event_to_topic(db, topic=topic, payload=payload, actor_user_id=user.id)
    db.commit()
    db.refresh(topic)
    return build_timeline_response(db, topic, granularity="auto")


@router.post("/v1/topics/{topic_id}/shares", response_model=ShareCreateResponse)
def create_topic_share(
    topic_id: str,
    payload: ShareCreateRequest,
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> ShareCreateResponse:
    user, _ = get_current_user(db, token)
    topic = ensure_topic_access(db.get(Topic, topic_id), user)
    share = create_share(
        db,
        topic=topic,
        actor=user,
        mode=payload.mode,
        allow_follow=payload.allow_follow,
        expires_in_hours=payload.expires_in_hours,
    )
    return ShareCreateResponse(
        code=share.code,
        url=f"{settings.public_share_base_url}/{share.code}",
        mode=share.mode,
        allow_follow=share.allow_follow,
        expires_at=share.expires_at,
    )


@router.get("/v1/public/shares/{code}", response_model=ShareOpenResponse)
def open_public_share(code: str, db: Session = Depends(get_db)) -> ShareOpenResponse:
    return open_share(db, code)


@router.get("/v1/recommendations/hot", response_model=RecommendationListResponse)
def recommendations_hot(
    limit: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db),
) -> RecommendationListResponse:
    return RecommendationListResponse(items=[TopicSummary.model_validate(topic) for topic in hot_topics(db, limit=limit)])


@router.get("/v1/recommendations/random", response_model=RecommendationListResponse)
def recommendations_random(
    limit: int = Query(default=settings.random_recommendation_batch_size, ge=1, le=50),
    db: Session = Depends(get_db),
) -> RecommendationListResponse:
    return RecommendationListResponse(items=[TopicSummary.model_validate(topic) for topic in random_topics(db, limit=limit)])


@router.get("/v1/recommendations/history", response_model=RecommendationListResponse)
def recommendations_history(
    token: str = Depends(require_auth_token),
    db: Session = Depends(get_db),
) -> RecommendationListResponse:
    user, _ = get_current_user(db, token)
    items = [history.topic for history in list_history(db, user, limit=settings.random_recommendation_batch_size)]
    return RecommendationListResponse(items=items)
