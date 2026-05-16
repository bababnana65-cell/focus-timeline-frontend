import enum
from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Enum as SAEnum, ForeignKey, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base, IdMixin, TimestampMixin, utcnow


class UserStatus(str, enum.Enum):
    active = "active"
    blocked = "blocked"


class TopicKind(str, enum.Enum):
    standard = "standard"
    user_created = "user_created"


class TopicVisibility(str, enum.Enum):
    public = "public"
    private = "private"
    shared = "shared"


class TopicStatus(str, enum.Enum):
    draft = "draft"
    active = "active"
    archived = "archived"
    hidden = "hidden"


class TimePrecision(str, enum.Enum):
    hour = "hour"
    day = "day"
    month = "month"
    year = "year"
    decade = "decade"
    century = "century"
    era = "era"
    approximate = "approximate"


class SourceType(str, enum.Enum):
    official = "official"
    media = "media"
    research = "research"
    community = "community"
    aggregator = "aggregator"
    wire = "wire"
    social = "social"
    archive = "archive"
    user_upload = "user_upload"


class ReviewStatus(str, enum.Enum):
    pending = "pending"
    verified = "verified"
    disputed = "disputed"
    rejected = "rejected"


class ImportanceLevel(str, enum.Enum):
    major = "major"
    normal = "normal"
    minor = "minor"


class LinkRole(str, enum.Enum):
    direct = "direct"
    background = "background"
    impact = "impact"
    context = "context"


class NotificationLevel(str, enum.Enum):
    off = "off"
    major_only = "major_only"
    all = "all"


class ShareMode(str, enum.Enum):
    live = "live"
    snapshot = "snapshot"


class SortOrder(str, enum.Enum):
    chronological = "chronological"
    reverse_chronological = "reverseChronological"


class User(Base, IdMixin, TimestampMixin):
    __tablename__ = "users"

    phone_number: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    nickname: Mapped[str] = mapped_column(String(100), nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(String(512))
    timezone: Mapped[str] = mapped_column(String(64), default="Asia/Shanghai", nullable=False)
    locale: Mapped[str] = mapped_column(String(32), default="zh-CN", nullable=False)
    status: Mapped[UserStatus] = mapped_column(SAEnum(UserStatus), default=UserStatus.active, nullable=False)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    preferences: Mapped["UserPreference | None"] = relationship(
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    sessions: Mapped[list["UserSession"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    owned_topics: Mapped[list["Topic"]] = relationship(back_populates="owner")
    follows: Mapped[list["UserTopicFollow"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    view_history: Mapped[list["TopicViewHistory"]] = relationship(back_populates="user", cascade="all, delete-orphan")


class UserPreference(Base, IdMixin, TimestampMixin):
    __tablename__ = "user_preferences"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    default_sort_order: Mapped[SortOrder] = mapped_column(
        SAEnum(SortOrder),
        default=SortOrder.chronological,
        nullable=False,
    )
    selected_topic_id: Mapped[str | None] = mapped_column(ForeignKey("topics.id", ondelete="SET NULL"))
    home_recommendation_mode: Mapped[str] = mapped_column(String(32), default="hot", nullable=False)

    user: Mapped[User] = relationship(back_populates="preferences")
    selected_topic: Mapped["Topic | None"] = relationship(foreign_keys=[selected_topic_id])


class UserSession(Base, IdMixin, TimestampMixin):
    __tablename__ = "user_sessions"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    device_id: Mapped[str | None] = mapped_column(String(128))
    device_name: Mapped[str | None] = mapped_column(String(128))
    client_platform: Mapped[str | None] = mapped_column(String(64))
    app_version: Mapped[str | None] = mapped_column(String(64))
    ip_address: Mapped[str | None] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped[User] = relationship(back_populates="sessions")


class SmsChallenge(Base, IdMixin, TimestampMixin):
    __tablename__ = "sms_challenges"

    phone_number: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    code_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    purpose: Mapped[str] = mapped_column(String(32), default="login", nullable=False)
    provider: Mapped[str] = mapped_column(String(64), default="debug", nullable=False)
    debug_code: Mapped[str | None] = mapped_column(String(16))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    consumed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    request_ip: Mapped[str | None] = mapped_column(String(64))
    send_count: Mapped[int] = mapped_column(Integer, default=1, nullable=False)


class Topic(Base, IdMixin, TimestampMixin):
    __tablename__ = "topics"

    slug: Mapped[str | None] = mapped_column(String(255), unique=True)
    owner_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    kind: Mapped[TopicKind] = mapped_column(SAEnum(TopicKind), default=TopicKind.standard, nullable=False)
    visibility: Mapped[TopicVisibility] = mapped_column(
        SAEnum(TopicVisibility),
        default=TopicVisibility.public,
        nullable=False,
    )
    status: Mapped[TopicStatus] = mapped_column(SAEnum(TopicStatus), default=TopicStatus.active, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    tagline: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    core_keywords: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    related_keywords: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    excluded_keywords: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    start_time_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    start_time_precision: Mapped[TimePrecision] = mapped_column(
        SAEnum(TimePrecision),
        default=TimePrecision.day,
        nullable=False,
    )
    start_time_label: Mapped[str | None] = mapped_column(String(128))
    share_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_hot: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    follower_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    event_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    latest_event_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    current_revision: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    owner: Mapped[User | None] = relationship(back_populates="owned_topics")
    revisions: Mapped[list["TopicRevision"]] = relationship(back_populates="topic", cascade="all, delete-orphan")
    event_links: Mapped[list["TopicEventLink"]] = relationship(back_populates="topic", cascade="all, delete-orphan")
    follows: Mapped[list["UserTopicFollow"]] = relationship(back_populates="topic", cascade="all, delete-orphan")
    share_links: Mapped[list["ShareLink"]] = relationship(back_populates="topic", cascade="all, delete-orphan")


class TopicRevision(Base, IdMixin, TimestampMixin):
    __tablename__ = "topic_revisions"
    __table_args__ = (UniqueConstraint("topic_id", "revision_number"),)

    topic_id: Mapped[str] = mapped_column(ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    revision_number: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    tagline: Mapped[str] = mapped_column(String(255), default="", nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    core_keywords: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    related_keywords: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    excluded_keywords: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    start_time_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    start_time_precision: Mapped[TimePrecision] = mapped_column(SAEnum(TimePrecision), nullable=False)
    start_time_label: Mapped[str | None] = mapped_column(String(128))
    change_summary: Mapped[str | None] = mapped_column(String(255))
    created_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))

    topic: Mapped[Topic] = relationship(back_populates="revisions")


class EventNode(Base, IdMixin, TimestampMixin):
    __tablename__ = "event_nodes"

    canonical_key: Mapped[str | None] = mapped_column(String(128), unique=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str] = mapped_column(Text, default="", nullable=False)
    detail: Mapped[str] = mapped_column(Text, default="", nullable=False)
    event_time_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    event_time_end_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    time_precision: Mapped[TimePrecision] = mapped_column(SAEnum(TimePrecision), default=TimePrecision.day, nullable=False)
    time_label: Mapped[str | None] = mapped_column(String(128))
    importance: Mapped[ImportanceLevel] = mapped_column(
        SAEnum(ImportanceLevel),
        default=ImportanceLevel.normal,
        nullable=False,
    )
    review_status: Mapped[ReviewStatus] = mapped_column(
        SAEnum(ReviewStatus),
        default=ReviewStatus.pending,
        nullable=False,
    )
    confidence_score: Mapped[float] = mapped_column(Numeric(5, 2), default=0.7, nullable=False)
    created_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    current_revision: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    sources: Mapped[list["EventSource"]] = relationship(back_populates="event_node", cascade="all, delete-orphan")
    revisions: Mapped[list["EventNodeRevision"]] = relationship(
        back_populates="event_node",
        cascade="all, delete-orphan",
    )
    topic_links: Mapped[list["TopicEventLink"]] = relationship(back_populates="event_node", cascade="all, delete-orphan")


class EventNodeRevision(Base, IdMixin, TimestampMixin):
    __tablename__ = "event_node_revisions"
    __table_args__ = (UniqueConstraint("event_node_id", "revision_number"),)

    event_node_id: Mapped[str] = mapped_column(ForeignKey("event_nodes.id", ondelete="CASCADE"), nullable=False, index=True)
    revision_number: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str] = mapped_column(Text, default="", nullable=False)
    detail: Mapped[str] = mapped_column(Text, default="", nullable=False)
    event_time_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    event_time_end_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    time_precision: Mapped[TimePrecision] = mapped_column(SAEnum(TimePrecision), nullable=False)
    time_label: Mapped[str | None] = mapped_column(String(128))
    importance: Mapped[ImportanceLevel] = mapped_column(SAEnum(ImportanceLevel), nullable=False)
    review_status: Mapped[ReviewStatus] = mapped_column(SAEnum(ReviewStatus), nullable=False)
    confidence_score: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    change_summary: Mapped[str | None] = mapped_column(String(255))
    created_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))

    event_node: Mapped[EventNode] = relationship(back_populates="revisions")


class EventSource(Base, IdMixin, TimestampMixin):
    __tablename__ = "event_sources"

    event_node_id: Mapped[str] = mapped_column(ForeignKey("event_nodes.id", ondelete="CASCADE"), nullable=False, index=True)
    source_type: Mapped[SourceType] = mapped_column(SAEnum(SourceType), default=SourceType.media, nullable=False)
    publisher_name: Mapped[str] = mapped_column(String(255), nullable=False)
    source_title: Mapped[str | None] = mapped_column(String(255))
    source_url: Mapped[str | None] = mapped_column(String(1024))
    source_published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    reliability_score: Mapped[float] = mapped_column(Numeric(5, 2), default=0.7, nullable=False)
    evidence_note: Mapped[str | None] = mapped_column(Text)
    raw_excerpt: Mapped[str | None] = mapped_column(Text)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    event_node: Mapped[EventNode] = relationship(back_populates="sources")


class TopicEventLink(Base, IdMixin, TimestampMixin):
    __tablename__ = "topic_event_links"
    __table_args__ = (UniqueConstraint("topic_id", "event_node_id"),)

    topic_id: Mapped[str] = mapped_column(ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    event_node_id: Mapped[str] = mapped_column(ForeignKey("event_nodes.id", ondelete="CASCADE"), nullable=False, index=True)
    relation_role: Mapped[LinkRole] = mapped_column(SAEnum(LinkRole), default=LinkRole.direct, nullable=False)
    relevance_score: Mapped[float] = mapped_column(Numeric(5, 2), default=1.0, nullable=False)
    link_reason: Mapped[str | None] = mapped_column(Text)
    bucket_hint: Mapped[TimePrecision | None] = mapped_column(SAEnum(TimePrecision))
    manual_rank: Mapped[int | None] = mapped_column(Integer)
    is_primary_topic: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    topic: Mapped[Topic] = relationship(back_populates="event_links")
    event_node: Mapped[EventNode] = relationship(back_populates="topic_links")


class UserTopicFollow(Base, IdMixin, TimestampMixin):
    __tablename__ = "user_topic_follows"
    __table_args__ = (UniqueConstraint("user_id", "topic_id"),)

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    topic_id: Mapped[str] = mapped_column(ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    is_pinned: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    pin_rank: Mapped[int | None] = mapped_column(Integer)
    custom_sort_rank: Mapped[int | None] = mapped_column(Integer)
    notification_level: Mapped[NotificationLevel] = mapped_column(
        SAEnum(NotificationLevel),
        default=NotificationLevel.major_only,
        nullable=False,
    )
    followed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)

    user: Mapped[User] = relationship(back_populates="follows")
    topic: Mapped[Topic] = relationship(back_populates="follows")


class TopicViewHistory(Base, IdMixin, TimestampMixin):
    __tablename__ = "topic_view_history"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    topic_id: Mapped[str] = mapped_column(ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    event_node_id: Mapped[str | None] = mapped_column(ForeignKey("event_nodes.id", ondelete="SET NULL"))
    opened_from: Mapped[str | None] = mapped_column(String(64))
    viewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)

    user: Mapped[User] = relationship(back_populates="view_history")
    topic: Mapped[Topic] = relationship()
    event_node: Mapped[EventNode | None] = relationship()


class ShareLink(Base, IdMixin, TimestampMixin):
    __tablename__ = "share_links"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    topic_id: Mapped[str] = mapped_column(ForeignKey("topics.id", ondelete="CASCADE"), nullable=False, index=True)
    created_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    mode: Mapped[ShareMode] = mapped_column(SAEnum(ShareMode), default=ShareMode.live, nullable=False)
    allow_follow: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    snapshot_payload: Mapped[dict | None] = mapped_column(JSON)
    snapshot_revision: Mapped[int | None] = mapped_column(Integer)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    opened_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_opened_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    topic: Mapped[Topic] = relationship(back_populates="share_links")
    creator: Mapped[User | None] = relationship()
