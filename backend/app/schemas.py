from datetime import datetime
from decimal import Decimal
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, model_validator

from .models import ImportanceLevel, LinkRole, NotificationLevel, ShareMode, SortOrder, SourceType, TimePrecision, TopicKind, TopicStatus, TopicVisibility


def to_camel(value: str) -> str:
    head, *tail = value.split("_")
    return head + "".join(part.capitalize() for part in tail)


class ApiModel(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=to_camel,
        use_enum_values=True,
    )


class HealthResponse(ApiModel):
    status: str
    app_name: str
    environment: str


class MessageResponse(ApiModel):
    message: str


class UserProfile(ApiModel):
    id: str
    phone_number: str
    nickname: str
    avatar_url: str | None = None
    timezone: str
    locale: str


class UserPreferencePayload(ApiModel):
    default_sort_order: SortOrder
    selected_topic_id: str | None = None
    home_recommendation_mode: str = "hot"


class SmsSendRequest(ApiModel):
    phone_number: str
    purpose: str = "login"


class SmsSendResponse(ApiModel):
    challenge_id: str
    expires_in_seconds: int
    debug_code: str | None = None


class SmsVerifyRequest(ApiModel):
    challenge_id: str
    phone_number: str
    code: str
    device_id: str | None = None
    device_name: str | None = None
    client_platform: str | None = None
    app_version: str | None = None


class AuthSessionResponse(ApiModel):
    access_token: str
    token_type: str = "Bearer"
    expires_at: datetime
    user: UserProfile
    preferences: UserPreferencePayload


class TopicSummary(ApiModel):
    id: str
    slug: str | None = None
    kind: TopicKind
    visibility: TopicVisibility
    status: TopicStatus
    owner_user_id: str | None = None
    title: str
    tagline: str
    description: str
    core_keywords: list[str] = Field(default_factory=list)
    related_keywords: list[str] = Field(default_factory=list)
    excluded_keywords: list[str] = Field(default_factory=list)
    start_time_at: datetime | None = None
    start_time_precision: TimePrecision
    start_time_label: str | None = None
    share_enabled: bool
    is_hot: bool
    follower_count: int
    event_count: int
    latest_event_time: datetime | None = None
    current_revision: int


class EventSourcePayload(ApiModel):
    id: str | None = None
    source_type: SourceType
    publisher_name: str
    source_title: str | None = None
    source_url: str | None = None
    source_published_at: datetime | None = None
    reliability_score: Decimal | float = 0.7
    evidence_note: str | None = None
    raw_excerpt: str | None = None
    is_primary: bool = False


class EventAttachRequest(ApiModel):
    existing_event_node_id: str | None = None
    title: str | None = None
    summary: str | None = None
    detail: str | None = None
    event_time_at: datetime | None = None
    event_time_end_at: datetime | None = None
    time_precision: TimePrecision = TimePrecision.day
    time_label: str | None = None
    importance: ImportanceLevel = ImportanceLevel.normal
    confidence_score: Decimal | float = 0.7
    relation_role: LinkRole = LinkRole.direct
    relevance_score: Decimal | float = 1.0
    link_reason: str | None = None
    bucket_hint: TimePrecision | None = None
    sources: list[EventSourcePayload] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_payload(self) -> "EventAttachRequest":
        if self.existing_event_node_id:
            return self
        if not self.title or not self.event_time_at:
            raise ValueError("creating a new event requires title and event_time_at")
        return self


class TopicCreateRequest(ApiModel):
    title: str
    tagline: str = ""
    description: str = ""
    core_keywords: list[str] = Field(default_factory=list)
    related_keywords: list[str] = Field(default_factory=list)
    excluded_keywords: list[str] = Field(default_factory=list)
    start_time_at: datetime | None = None
    start_time_precision: TimePrecision = TimePrecision.day
    start_time_label: str | None = None
    visibility: TopicVisibility = TopicVisibility.private
    share_enabled: bool = True
    seed_events: list[EventAttachRequest] = Field(default_factory=list)


class FollowCreateRequest(ApiModel):
    topic_id: str


class FollowUpdateRequest(ApiModel):
    is_pinned: bool | None = None
    pin_rank: int | None = None
    custom_sort_rank: int | None = None
    notification_level: NotificationLevel | None = None


class TopicFollowPayload(ApiModel):
    topic: TopicSummary
    is_pinned: bool
    pin_rank: int | None = None
    custom_sort_rank: int | None = None
    notification_level: NotificationLevel
    followed_at: datetime


class HistoryCreateRequest(ApiModel):
    topic_id: str
    event_node_id: str | None = None
    opened_from: str | None = None


class HistoryItem(ApiModel):
    topic: TopicSummary
    last_viewed_at: datetime
    view_count: int


class EventNodePayload(ApiModel):
    id: str
    title: str
    summary: str
    detail: str
    event_time_at: datetime
    event_time_end_at: datetime | None = None
    time_precision: TimePrecision
    time_label: str | None = None
    importance: ImportanceLevel
    review_status: str
    confidence_score: Decimal | float
    relation_role: LinkRole
    relevance_score: Decimal | float
    link_reason: str | None = None
    bucket_hint: TimePrecision | None = None
    is_primary_topic: bool
    sources: list[EventSourcePayload] = Field(default_factory=list)


class TimelineBucketPayload(ApiModel):
    id: str
    label: str
    headline: str
    period_start: datetime
    granularity: TimePrecision
    event_count: int
    contains_major_event: bool


class TimelineResponse(ApiModel):
    topic: TopicSummary
    granularity: TimePrecision
    total_event_count: int
    bucket_count: int
    buckets: list[TimelineBucketPayload]
    events: list[EventNodePayload]


class ShareCreateRequest(ApiModel):
    mode: ShareMode = ShareMode.live
    allow_follow: bool = True
    expires_in_hours: int | None = 72


class ShareCreateResponse(ApiModel):
    code: str
    url: str
    mode: ShareMode
    allow_follow: bool
    expires_at: datetime | None = None


class ShareOpenResponse(ApiModel):
    code: str
    mode: ShareMode
    allow_follow: bool
    expires_at: datetime | None = None
    topic: TopicSummary
    timeline: TimelineResponse


class RecommendationListResponse(ApiModel):
    items: list[TopicSummary]


class BootstrapResponse(ApiModel):
    user: UserProfile
    preferences: UserPreferencePayload
    follows: list[TopicFollowPayload]
    history: list[HistoryItem]
    hot_topics: list[TopicSummary]


class PreferenceUpdateRequest(ApiModel):
    default_sort_order: SortOrder | None = None
    selected_topic_id: str | None = None
    home_recommendation_mode: str | None = None


def dump_payload(model: BaseModel) -> dict[str, Any]:
    return model.model_dump(mode="json", by_alias=False)
