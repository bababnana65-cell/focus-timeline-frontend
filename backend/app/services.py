import hashlib
import secrets
from collections import OrderedDict
from collections.abc import Sequence
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import Header, HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, joinedload, selectinload

from .config import settings
from .database import utcnow
from .models import EventNode, EventNodeRevision, EventSource, ImportanceLevel, LinkRole, NotificationLevel, ReviewStatus, ShareLink, ShareMode, SmsChallenge, SourceType, Topic, TopicEventLink, TopicKind, TopicRevision, TopicStatus, TopicViewHistory, TopicVisibility, User, UserPreference, UserSession, UserTopicFollow
from .schemas import EventAttachRequest, EventNodePayload, EventSourcePayload, HistoryItem, TimelineBucketPayload, TimelineResponse, TopicFollowPayload, TopicSummary, UserPreferencePayload, UserProfile, dump_payload


def require_auth_token(authorization: str | None = Header(default=None)) -> str:
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing bearer token")
    return authorization.split(" ", 1)[1].strip()


def normalize_phone_number(raw: str) -> str:
    digits = "".join(char for char in raw if char.isdigit())
    if len(digits) == 11 and digits.startswith("1"):
        return f"+86{digits}"
    if len(digits) == 13 and digits.startswith("86"):
        return f"+{digits}"
    if raw.startswith("+") and 8 <= len(digits) <= 15:
        return f"+{digits}"
    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="invalid phone number")


def hash_value(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def generate_sms_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def generate_session_token() -> str:
    return secrets.token_urlsafe(32)


def generate_share_code() -> str:
    return secrets.token_urlsafe(9).replace("-", "").replace("_", "")


def user_profile_from_model(user: User) -> UserProfile:
    return UserProfile.model_validate(user)


def preference_payload_from_model(preference: UserPreference) -> UserPreferencePayload:
    return UserPreferencePayload.model_validate(preference)


def topic_summary_from_model(topic: Topic) -> TopicSummary:
    return TopicSummary.model_validate(topic)


def ensure_user_preferences(db: Session, user: User) -> UserPreference:
    if user.preferences is not None:
        return user.preferences
    preference = UserPreference(user_id=user.id)
    db.add(preference)
    db.flush()
    return preference


def send_sms_challenge(
    db: Session,
    phone_number: str,
    purpose: str = "login",
    request_ip: str | None = None,
) -> tuple[SmsChallenge, str | None]:
    normalized_phone = normalize_phone_number(phone_number)
    code = generate_sms_code()
    challenge = SmsChallenge(
        phone_number=normalized_phone,
        code_hash=hash_value(code),
        purpose=purpose,
        provider="debug",
        debug_code=code if settings.sms_debug_return_code else None,
        expires_at=utcnow() + timedelta(seconds=settings.sms_code_ttl_seconds),
        request_ip=request_ip,
    )
    db.add(challenge)
    db.commit()
    db.refresh(challenge)
    return challenge, challenge.debug_code


def verify_sms_login(
    db: Session,
    challenge_id: str,
    phone_number: str,
    code: str,
    *,
    device_id: str | None = None,
    device_name: str | None = None,
    client_platform: str | None = None,
    app_version: str | None = None,
    ip_address: str | None = None,
) -> tuple[str, UserSession, User]:
    normalized_phone = normalize_phone_number(phone_number)
    challenge = db.get(SmsChallenge, challenge_id)
    if challenge is None or challenge.phone_number != normalized_phone:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="sms challenge not found")
    now = utcnow()
    if challenge.consumed_at is not None or challenge.expires_at < now:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="sms challenge expired")
    if challenge.code_hash != hash_value(code.strip()):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="invalid verification code")

    challenge.consumed_at = now

    user = db.scalar(select(User).where(User.phone_number == normalized_phone))
    if user is None:
        user = User(
            phone_number=normalized_phone,
            nickname=f"用户{normalized_phone[-4:]}",
        )
        db.add(user)
        db.flush()
    user.last_login_at = now

    ensure_user_preferences(db, user)

    raw_token = generate_session_token()
    session = UserSession(
        user_id=user.id,
        token_hash=hash_value(raw_token),
        device_id=device_id,
        device_name=device_name,
        client_platform=client_platform,
        app_version=app_version,
        ip_address=ip_address,
        expires_at=now + timedelta(hours=settings.session_ttl_hours),
        last_seen_at=now,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    db.refresh(user)
    return raw_token, session, user


def get_session_by_token(db: Session, token: str) -> UserSession:
    session = db.scalar(select(UserSession).where(UserSession.token_hash == hash_value(token)))
    if session is None or session.revoked_at is not None or session.expires_at < utcnow():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="session expired")
    session.last_seen_at = utcnow()
    db.commit()
    db.refresh(session)
    return session


def get_current_user(db: Session, token: str) -> tuple[User, UserSession]:
    session = get_session_by_token(db, token)
    user = session.user
    if user.status.value != "active":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="user is blocked")
    return user, session


def revoke_session(db: Session, session: UserSession) -> None:
    session.revoked_at = utcnow()
    db.commit()


def ensure_topic_access(topic: Topic | None, user: User | None = None) -> Topic:
    if topic is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="topic not found")
    if topic.visibility != TopicVisibility.private:
        return topic
    if user is None or topic.owner_user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="topic is private")
    return topic


def ensure_topic_owner(topic: Topic, user: User) -> Topic:
    if topic.owner_user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="topic write access denied")
    return topic


def create_topic_revision(db: Session, topic: Topic, *, actor_user_id: str | None, change_summary: str | None) -> None:
    revision = TopicRevision(
        topic_id=topic.id,
        revision_number=topic.current_revision,
        title=topic.title,
        tagline=topic.tagline,
        description=topic.description,
        core_keywords=topic.core_keywords,
        related_keywords=topic.related_keywords,
        excluded_keywords=topic.excluded_keywords,
        start_time_at=topic.start_time_at,
        start_time_precision=topic.start_time_precision,
        start_time_label=topic.start_time_label,
        change_summary=change_summary,
        created_by_user_id=actor_user_id,
    )
    db.add(revision)


def create_event_revision(db: Session, event_node: EventNode, *, actor_user_id: str | None, change_summary: str | None) -> None:
    revision = EventNodeRevision(
        event_node_id=event_node.id,
        revision_number=event_node.current_revision,
        title=event_node.title,
        summary=event_node.summary,
        detail=event_node.detail,
        event_time_at=event_node.event_time_at,
        event_time_end_at=event_node.event_time_end_at,
        time_precision=event_node.time_precision,
        time_label=event_node.time_label,
        importance=event_node.importance,
        review_status=event_node.review_status,
        confidence_score=event_node.confidence_score,
        change_summary=change_summary,
        created_by_user_id=actor_user_id,
    )
    db.add(revision)


def refresh_topic_counters(db: Session, topic: Topic) -> None:
    link_count = db.scalar(select(func.count(TopicEventLink.id)).where(TopicEventLink.topic_id == topic.id)) or 0
    latest_event = db.scalar(
        select(func.max(EventNode.event_time_at))
        .join(TopicEventLink, TopicEventLink.event_node_id == EventNode.id)
        .where(TopicEventLink.topic_id == topic.id)
    )
    follower_count = db.scalar(select(func.count(UserTopicFollow.id)).where(UserTopicFollow.topic_id == topic.id)) or 0
    topic.event_count = int(link_count)
    topic.latest_event_time = latest_event
    topic.follower_count = int(follower_count)


def create_event_sources(db: Session, event_node: EventNode, sources: Sequence[EventSourcePayload]) -> None:
    for source in sources:
        db.add(
            EventSource(
                event_node_id=event_node.id,
                source_type=source.source_type,
                publisher_name=source.publisher_name,
                source_title=source.source_title,
                source_url=source.source_url,
                source_published_at=source.source_published_at,
                reliability_score=float(source.reliability_score),
                evidence_note=source.evidence_note,
                raw_excerpt=source.raw_excerpt,
                is_primary=source.is_primary,
            )
        )


def create_new_event(db: Session, payload: EventAttachRequest, actor_user_id: str | None) -> EventNode:
    event_node = EventNode(
        title=payload.title or "",
        summary=payload.summary or "",
        detail=payload.detail or payload.summary or "",
        event_time_at=payload.event_time_at or utcnow(),
        event_time_end_at=payload.event_time_end_at,
        time_precision=payload.time_precision,
        time_label=payload.time_label,
        importance=payload.importance,
        review_status=ReviewStatus.pending,
        confidence_score=float(payload.confidence_score),
        created_by_user_id=actor_user_id,
    )
    db.add(event_node)
    db.flush()
    create_event_sources(db, event_node, payload.sources)
    create_event_revision(db, event_node, actor_user_id=actor_user_id, change_summary="initial event revision")
    return event_node


def attach_event_to_topic(
    db: Session,
    *,
    topic: Topic,
    payload: EventAttachRequest,
    actor_user_id: str | None,
) -> EventNode:
    if payload.existing_event_node_id:
        event_node = db.get(EventNode, payload.existing_event_node_id)
        if event_node is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="event node not found")
    else:
        event_node = create_new_event(db, payload, actor_user_id)

    existing_link = db.scalar(
        select(TopicEventLink).where(
            TopicEventLink.topic_id == topic.id,
            TopicEventLink.event_node_id == event_node.id,
        )
    )
    if existing_link is None:
        db.add(
            TopicEventLink(
                topic_id=topic.id,
                event_node_id=event_node.id,
                relation_role=payload.relation_role,
                relevance_score=float(payload.relevance_score),
                link_reason=payload.link_reason,
                bucket_hint=payload.bucket_hint,
                is_primary_topic=False,
            )
        )
    refresh_topic_counters(db, topic)
    db.flush()
    return event_node


def create_user_topic(
    db: Session,
    owner: User,
    *,
    title: str,
    tagline: str,
    description: str,
    core_keywords: list[str],
    related_keywords: list[str],
    excluded_keywords: list[str],
    start_time_at: datetime | None,
    start_time_precision,
    start_time_label: str | None,
    visibility,
    share_enabled: bool,
    seed_events: Sequence[EventAttachRequest],
) -> Topic:
    topic = Topic(
        owner_user_id=owner.id,
        kind=TopicKind.user_created,
        visibility=visibility,
        status=TopicStatus.active,
        title=title,
        tagline=tagline,
        description=description,
        core_keywords=core_keywords,
        related_keywords=related_keywords,
        excluded_keywords=excluded_keywords,
        start_time_at=start_time_at,
        start_time_precision=start_time_precision,
        start_time_label=start_time_label,
        share_enabled=share_enabled,
        is_hot=False,
    )
    db.add(topic)
    db.flush()
    create_topic_revision(db, topic, actor_user_id=owner.id, change_summary="initial topic revision")

    for event_payload in seed_events:
        attach_event_to_topic(db, topic=topic, payload=event_payload, actor_user_id=owner.id)

    db.add(UserTopicFollow(user_id=owner.id, topic_id=topic.id))
    refresh_topic_counters(db, topic)
    db.commit()
    db.refresh(topic)
    return topic


def list_topics(db: Session, *, user: User | None, scope: str = "discover", search: str | None = None) -> list[Topic]:
    stmt = select(Topic).where(Topic.status == TopicStatus.active)
    if scope == "mine":
        if user is None:
            return []
        stmt = stmt.where(Topic.owner_user_id == user.id)
    elif scope == "following":
        if user is None:
            return []
        stmt = (
            select(Topic)
            .join(UserTopicFollow, UserTopicFollow.topic_id == Topic.id)
            .where(UserTopicFollow.user_id == user.id, Topic.status == TopicStatus.active)
        )
    else:
        if user is None:
            stmt = stmt.where(Topic.visibility != TopicVisibility.private)
        else:
            stmt = stmt.where(or_(Topic.visibility != TopicVisibility.private, Topic.owner_user_id == user.id))

    if search:
        like_term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Topic.title.ilike(like_term),
                Topic.tagline.ilike(like_term),
                Topic.description.ilike(like_term),
            )
        )

    stmt = stmt.order_by(
        Topic.is_hot.desc(),
        Topic.follower_count.desc(),
        Topic.latest_event_time.desc().nullslast(),
        Topic.created_at.desc(),
    )
    return list(db.scalars(stmt).unique().all())


def list_follows(db: Session, user: User) -> list[UserTopicFollow]:
    stmt = (
        select(UserTopicFollow)
        .options(selectinload(UserTopicFollow.topic))
        .where(UserTopicFollow.user_id == user.id)
        .order_by(
            UserTopicFollow.is_pinned.desc(),
            UserTopicFollow.pin_rank.asc().nullslast(),
            UserTopicFollow.followed_at.desc(),
        )
    )
    return list(db.scalars(stmt).all())


def follow_topic(db: Session, user: User, topic: Topic) -> UserTopicFollow:
    follow = db.scalar(
        select(UserTopicFollow).where(UserTopicFollow.user_id == user.id, UserTopicFollow.topic_id == topic.id)
    )
    if follow is not None:
        return follow
    follow = UserTopicFollow(user_id=user.id, topic_id=topic.id)
    db.add(follow)
    db.flush()
    refresh_topic_counters(db, topic)
    db.commit()
    db.refresh(follow)
    return follow


def update_follow(
    db: Session,
    user: User,
    topic: Topic,
    *,
    is_pinned: bool | None,
    pin_rank: int | None,
    custom_sort_rank: int | None,
    notification_level,
) -> UserTopicFollow:
    follow = db.scalar(
        select(UserTopicFollow).where(UserTopicFollow.user_id == user.id, UserTopicFollow.topic_id == topic.id)
    )
    if follow is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="follow relationship not found")
    if is_pinned is not None:
        follow.is_pinned = is_pinned
    if pin_rank is not None or is_pinned is False:
        follow.pin_rank = pin_rank
    if custom_sort_rank is not None:
        follow.custom_sort_rank = custom_sort_rank
    if notification_level is not None:
        follow.notification_level = notification_level
    db.commit()
    db.refresh(follow)
    return follow


def unfollow_topic(db: Session, user: User, topic: Topic) -> None:
    follow = db.scalar(
        select(UserTopicFollow).where(UserTopicFollow.user_id == user.id, UserTopicFollow.topic_id == topic.id)
    )
    if follow is None:
        return
    db.delete(follow)
    db.flush()
    refresh_topic_counters(db, topic)
    db.commit()


def record_topic_view(
    db: Session,
    user: User,
    *,
    topic_id: str,
    event_node_id: str | None,
    opened_from: str | None,
) -> TopicViewHistory:
    topic = db.get(Topic, topic_id)
    ensure_topic_access(topic, user)
    history = TopicViewHistory(
        user_id=user.id,
        topic_id=topic_id,
        event_node_id=event_node_id,
        opened_from=opened_from,
        viewed_at=utcnow(),
    )
    db.add(history)
    db.commit()
    db.refresh(history)
    return history


def list_history(db: Session, user: User, *, limit: int = 20) -> list[HistoryItem]:
    stmt = (
        select(TopicViewHistory)
        .options(selectinload(TopicViewHistory.topic))
        .where(TopicViewHistory.user_id == user.id)
        .order_by(TopicViewHistory.viewed_at.desc())
    )
    rows = list(db.scalars(stmt).all())
    grouped: OrderedDict[str, list[TopicViewHistory]] = OrderedDict()
    for row in rows:
        if row.topic_id not in grouped:
            grouped[row.topic_id] = []
        grouped[row.topic_id].append(row)

    result: list[HistoryItem] = []
    for records in list(grouped.values())[:limit]:
        first = records[0]
        result.append(
            HistoryItem(
                topic=topic_summary_from_model(first.topic),
                last_viewed_at=first.viewed_at,
                view_count=len(records),
            )
        )
    return result


def resolve_timeline_granularity(events: Sequence[EventNodePayload], requested: str | None):
    if requested and requested != "auto":
        try:
            return event_precision(requested)
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="invalid granularity") from exc

    if not events:
        return event_precision("day")

    first_time = min(event.event_time_at for event in events)
    last_time = max(event.event_time_at for event in events)
    span_days = max((last_time - first_time).days, 0)
    recent_threshold = datetime.now(timezone.utc) - timedelta(hours=24)
    if last_time >= recent_threshold and span_days <= 1:
        return event_precision("hour")
    if span_days <= 90:
        return event_precision("day")
    if span_days <= 365 * 3:
        return event_precision("month")
    if span_days <= 365 * 30:
        return event_precision("year")
    if span_days <= 365 * 300:
        return event_precision("decade")
    return event_precision("century")


def event_precision(value: str):
    from .models import TimePrecision

    return TimePrecision(value)


def bucket_start_for(event_time: datetime, granularity):
    if granularity.value == "hour":
        bucket = event_time.replace(minute=0, second=0, microsecond=0)
        label = bucket.strftime("%Y-%m-%d %H:00")
        return bucket, label
    if granularity.value == "day":
        bucket = event_time.replace(hour=0, minute=0, second=0, microsecond=0)
        label = bucket.strftime("%Y-%m-%d")
        return bucket, label
    if granularity.value == "month":
        bucket = event_time.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        label = bucket.strftime("%Y-%m")
        return bucket, label
    if granularity.value == "year":
        bucket = event_time.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        label = bucket.strftime("%Y")
        return bucket, label
    if granularity.value == "decade":
        decade_year = (event_time.year // 10) * 10
        bucket = event_time.replace(year=decade_year, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        label = f"{decade_year}s"
        return bucket, label
    century_year = ((event_time.year - 1) // 100) * 100 + 1
    bucket = event_time.replace(year=century_year, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
    label = f"{century_year}-{century_year + 99}"
    return bucket, label


def build_timeline_response(db: Session, topic: Topic, *, granularity: str | None = None) -> TimelineResponse:
    stmt = (
        select(TopicEventLink)
        .join(TopicEventLink.event_node)
        .options(joinedload(TopicEventLink.event_node).selectinload(EventNode.sources))
        .where(TopicEventLink.topic_id == topic.id)
        .order_by(TopicEventLink.manual_rank.asc().nullslast(), EventNode.event_time_at.asc())
    )
    links = list(db.scalars(stmt).all())

    events: list[EventNodePayload] = []
    min_datetime = datetime.min.replace(tzinfo=timezone.utc)
    for link in links:
        event_node = link.event_node
        sources = [
            EventSourcePayload.model_validate(source)
            for source in sorted(
                event_node.sources,
                key=lambda item: (not item.is_primary, item.source_published_at or min_datetime),
            )
        ]
        events.append(
            EventNodePayload(
                id=event_node.id,
                title=event_node.title,
                summary=event_node.summary,
                detail=event_node.detail,
                event_time_at=event_node.event_time_at,
                event_time_end_at=event_node.event_time_end_at,
                time_precision=event_node.time_precision,
                time_label=event_node.time_label,
                importance=event_node.importance,
                review_status=event_node.review_status.value,
                confidence_score=Decimal(str(event_node.confidence_score)),
                relation_role=link.relation_role,
                relevance_score=Decimal(str(link.relevance_score)),
                link_reason=link.link_reason,
                bucket_hint=link.bucket_hint,
                is_primary_topic=link.is_primary_topic,
                sources=sources,
            )
        )

    resolved_granularity = resolve_timeline_granularity(events, granularity)
    bucket_map: OrderedDict[str, dict[str, object]] = OrderedDict()
    for event in events:
        period_start, label = bucket_start_for(event.event_time_at, resolved_granularity)
        key = period_start.isoformat()
        current = bucket_map.setdefault(
            key,
            {
                "id": key,
                "label": label,
                "period_start": period_start,
                "granularity": resolved_granularity,
                "events": [],
            },
        )
        current["events"].append(event)

    buckets: list[TimelineBucketPayload] = []
    for current in bucket_map.values():
        bucket_events = current["events"]
        headline_source = next((event for event in bucket_events if event.importance == ImportanceLevel.major), bucket_events[0])
        buckets.append(
            TimelineBucketPayload(
                id=current["id"],
                label=current["label"],
                headline=headline_source.summary or headline_source.title,
                period_start=current["period_start"],
                granularity=current["granularity"],
                event_count=len(bucket_events),
                contains_major_event=any(event.importance == ImportanceLevel.major for event in bucket_events),
            )
        )

    return TimelineResponse(
        topic=topic_summary_from_model(topic),
        granularity=resolved_granularity,
        total_event_count=len(events),
        bucket_count=len(buckets),
        buckets=buckets,
        events=events,
    )


def create_share(
    db: Session,
    *,
    topic: Topic,
    actor: User,
    mode,
    allow_follow: bool,
    expires_in_hours: int | None,
) -> ShareLink:
    if not topic.share_enabled:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="topic sharing disabled")

    expires_at = utcnow() + timedelta(hours=expires_in_hours) if expires_in_hours else None
    snapshot_payload = None
    snapshot_revision = None
    if mode == ShareMode.snapshot:
        timeline = build_timeline_response(db, topic, granularity="auto")
        snapshot_payload = {
            "topic": dump_payload(topic_summary_from_model(topic)),
            "timeline": dump_payload(timeline),
        }
        snapshot_revision = topic.current_revision

    share = ShareLink(
        code=generate_share_code(),
        topic_id=topic.id,
        created_by_user_id=actor.id,
        mode=mode,
        allow_follow=allow_follow,
        snapshot_payload=snapshot_payload,
        snapshot_revision=snapshot_revision,
        expires_at=expires_at,
    )
    db.add(share)
    db.commit()
    db.refresh(share)
    return share


def open_share(db: Session, code: str):
    from .schemas import ShareOpenResponse

    share = db.scalar(select(ShareLink).options(selectinload(ShareLink.topic)).where(ShareLink.code == code))
    if share is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="share not found")
    if share.expires_at and share.expires_at < utcnow():
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="share expired")

    share.opened_count += 1
    share.last_opened_at = utcnow()

    if share.mode == ShareMode.snapshot and share.snapshot_payload:
        topic = TopicSummary.model_validate(share.snapshot_payload["topic"])
        timeline = TimelineResponse.model_validate(share.snapshot_payload["timeline"])
    else:
        topic_model = share.topic
        if topic_model is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="topic not found")
        topic = topic_summary_from_model(topic_model)
        timeline = build_timeline_response(db, topic_model, granularity="auto")

    db.commit()
    return ShareOpenResponse(
        code=share.code,
        mode=share.mode,
        allow_follow=share.allow_follow,
        expires_at=share.expires_at,
        topic=topic,
        timeline=timeline,
    )


def hot_topics(db: Session, *, limit: int = 10) -> list[Topic]:
    stmt = (
        select(Topic)
        .where(Topic.status == TopicStatus.active, Topic.visibility != TopicVisibility.private)
        .order_by(Topic.is_hot.desc(), Topic.follower_count.desc(), Topic.latest_event_time.desc().nullslast())
        .limit(limit)
    )
    return list(db.scalars(stmt).all())


def random_topics(db: Session, *, limit: int) -> list[Topic]:
    stmt = (
        select(Topic)
        .where(Topic.status == TopicStatus.active, Topic.visibility != TopicVisibility.private)
        .order_by(func.random())
        .limit(limit)
    )
    return list(db.scalars(stmt).all())


def bootstrap_payload(db: Session, user: User) -> tuple[list[TopicFollowPayload], list[HistoryItem], list[TopicSummary]]:
    follows = [
        TopicFollowPayload(
            topic=topic_summary_from_model(follow.topic),
            is_pinned=follow.is_pinned,
            pin_rank=follow.pin_rank,
            custom_sort_rank=follow.custom_sort_rank,
            notification_level=follow.notification_level,
            followed_at=follow.followed_at,
        )
        for follow in list_follows(db, user)
    ]
    history = list_history(db, user)
    hot = [topic_summary_from_model(topic) for topic in hot_topics(db)]
    return follows, history, hot


def seed_demo_data(db: Session) -> None:
    existing_standard_topic = db.scalar(select(Topic.id).where(Topic.kind == TopicKind.standard).limit(1))
    if existing_standard_topic is not None:
        return

    conflict_topic = Topic(
        slug="us-iran-conflict",
        kind=TopicKind.standard,
        visibility=TopicVisibility.public,
        status=TopicStatus.active,
        title="美伊战争总体进展",
        tagline="跟踪冲突升级、军事动作、外交回应和阶段变化",
        description="用于持续跟踪美伊冲突整体进展，重点关注会改变局势判断的关键节点。",
        core_keywords=["美伊战争", "美伊冲突", "美国", "伊朗"],
        related_keywords=["军事行动", "停火信号", "外交表态", "地区局势"],
        excluded_keywords=["纯市场评论", "无新增事实评论"],
        start_time_at=datetime(2026, 4, 1, tzinfo=timezone.utc),
        start_time_precision=event_precision("day"),
        start_time_label="2026年4月1日",
        share_enabled=True,
        is_hot=True,
    )
    missile_topic = Topic(
        slug="iran-missile-launches",
        kind=TopicKind.standard,
        visibility=TopicVisibility.public,
        status=TopicStatus.active,
        title="伊朗导弹发射情况",
        tagline="聚焦导弹发射批次、目标、拦截结果和官方确认",
        description="用于追踪伊朗导弹发射相关事实节点，不与整体战争时间线混淆。",
        core_keywords=["伊朗导弹", "导弹发射", "拦截结果"],
        related_keywords=["目标区域", "发射批次", "防空系统"],
        excluded_keywords=["泛外交评论", "无关航运消息"],
        start_time_at=datetime(2026, 4, 2, tzinfo=timezone.utc),
        start_time_precision=event_precision("day"),
        start_time_label="2026年4月2日",
        share_enabled=True,
        is_hot=True,
    )
    shipping_topic = Topic(
        slug="hormuz-shipping",
        kind=TopicKind.standard,
        visibility=TopicVisibility.public,
        status=TopicStatus.active,
        title="霍尔木兹海峡航运情况",
        tagline="关注航运预警、绕航、保险和通行风险变化",
        description="用于追踪霍尔木兹海峡航运运行状态和风险等级。",
        core_keywords=["霍尔木兹海峡", "航运", "油轮", "风险等级"],
        related_keywords=["绕航建议", "保险费率", "航运预警"],
        excluded_keywords=["内陆战况", "无关武器信息"],
        start_time_at=datetime(2026, 4, 3, tzinfo=timezone.utc),
        start_time_precision=event_precision("day"),
        start_time_label="2026年4月3日",
        share_enabled=True,
        is_hot=True,
    )
    db.add_all([conflict_topic, missile_topic, shipping_topic])
    db.flush()
    for topic in (conflict_topic, missile_topic, shipping_topic):
        create_topic_revision(db, topic, actor_user_id=None, change_summary="seed standard topic")

    event_airstrike = EventNode(
        title="美方空袭后局势正式升级",
        summary="冲突从高压对峙进入公开升级阶段。",
        detail="这条节点用于标记整体局势进入新的升级区间，是总体专题中的关键基准点。",
        event_time_at=datetime(2026, 4, 4, 3, 30, tzinfo=timezone.utc),
        time_precision=event_precision("hour"),
        time_label="2026年4月4日 11:30",
        importance=ImportanceLevel.major,
        review_status=ReviewStatus.verified,
        confidence_score=0.92,
    )
    event_missiles = EventNode(
        title="伊朗宣布对美军基地发射多轮导弹",
        summary="伊朗导弹发射由威慑表态转为实际行动。",
        detail="这条事实节点既属于总体冲突专题，也属于导弹发射专题，是多专题共享节点示例。",
        event_time_at=datetime(2026, 4, 5, 18, 0, tzinfo=timezone.utc),
        time_precision=event_precision("hour"),
        time_label="2026年4月6日 02:00",
        importance=ImportanceLevel.major,
        review_status=ReviewStatus.verified,
        confidence_score=0.96,
    )
    event_shipping_warning = EventNode(
        title="多家航运公司上调霍尔木兹风险等级",
        summary="霍尔木兹航运专题开始出现实质性风险升级节点。",
        detail="该节点既影响整体冲突判断，也直接属于海峡航运专题。",
        event_time_at=datetime(2026, 4, 6, 9, 0, tzinfo=timezone.utc),
        time_precision=event_precision("hour"),
        time_label="2026年4月6日 17:00",
        importance=ImportanceLevel.major,
        review_status=ReviewStatus.verified,
        confidence_score=0.91,
    )
    event_insurance = EventNode(
        title="保险费率和绕航建议同步更新",
        summary="风险已开始传导到具体航运运营和成本。",
        detail="这条节点是航运专题的下游影响节点，适合与预警升级节点并列展示。",
        event_time_at=datetime(2026, 4, 7, 8, 0, tzinfo=timezone.utc),
        time_precision=event_precision("hour"),
        time_label="2026年4月7日 16:00",
        importance=ImportanceLevel.normal,
        review_status=ReviewStatus.pending,
        confidence_score=0.82,
    )
    db.add_all([event_airstrike, event_missiles, event_shipping_warning, event_insurance])
    db.flush()

    db.add_all(
        [
            EventSource(
                event_node_id=event_airstrike.id,
                source_type=SourceType.official,
                publisher_name="官方通报",
                source_title="局势升级通报",
                source_url="https://example.com/conflict/official-briefing",
                reliability_score=0.95,
                is_primary=True,
            ),
            EventSource(
                event_node_id=event_missiles.id,
                source_type=SourceType.official,
                publisher_name="伊朗官方声明",
                source_title="导弹发射声明",
                source_url="https://example.com/missiles/statement",
                reliability_score=0.96,
                is_primary=True,
            ),
            EventSource(
                event_node_id=event_missiles.id,
                source_type=SourceType.media,
                publisher_name="国际媒体",
                source_title="导弹发射外部确认",
                source_url="https://example.com/missiles/media-confirmation",
                reliability_score=0.88,
                is_primary=False,
            ),
            EventSource(
                event_node_id=event_shipping_warning.id,
                source_type=SourceType.media,
                publisher_name="航运媒体",
                source_title="航运风险预警上调",
                source_url="https://example.com/shipping/risk",
                reliability_score=0.9,
                is_primary=True,
            ),
            EventSource(
                event_node_id=event_insurance.id,
                source_type=SourceType.research,
                publisher_name="保险观察简报",
                source_title="费率和绕航建议更新",
                source_url="https://example.com/shipping/insurance",
                reliability_score=0.82,
                is_primary=True,
            ),
        ]
    )

    for event_node in (event_airstrike, event_missiles, event_shipping_warning, event_insurance):
        create_event_revision(db, event_node, actor_user_id=None, change_summary="seed standard event")

    db.add_all(
        [
            TopicEventLink(
                topic_id=conflict_topic.id,
                event_node_id=event_airstrike.id,
                relation_role=LinkRole.direct,
                relevance_score=0.95,
                link_reason="标记整体局势升级起点",
                is_primary_topic=True,
            ),
            TopicEventLink(
                topic_id=conflict_topic.id,
                event_node_id=event_missiles.id,
                relation_role=LinkRole.direct,
                relevance_score=0.97,
                link_reason="导弹发射改变冲突阶段判断",
                is_primary_topic=False,
            ),
            TopicEventLink(
                topic_id=missile_topic.id,
                event_node_id=event_missiles.id,
                relation_role=LinkRole.direct,
                relevance_score=0.99,
                link_reason="导弹发射专题核心节点",
                is_primary_topic=True,
            ),
            TopicEventLink(
                topic_id=conflict_topic.id,
                event_node_id=event_shipping_warning.id,
                relation_role=LinkRole.impact,
                relevance_score=0.88,
                link_reason="航运风险变化反映冲突外溢影响",
                is_primary_topic=False,
            ),
            TopicEventLink(
                topic_id=shipping_topic.id,
                event_node_id=event_shipping_warning.id,
                relation_role=LinkRole.direct,
                relevance_score=0.99,
                link_reason="航运风险预警升级是该专题主节点",
                is_primary_topic=True,
            ),
            TopicEventLink(
                topic_id=shipping_topic.id,
                event_node_id=event_insurance.id,
                relation_role=LinkRole.impact,
                relevance_score=0.9,
                link_reason="风险开始传导到保险和绕航建议",
                is_primary_topic=False,
            ),
        ]
    )

    for topic in (conflict_topic, missile_topic, shipping_topic):
        refresh_topic_counters(db, topic)

    db.commit()
