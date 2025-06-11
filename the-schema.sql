CREATE TABLE public."Actor" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "ActorTypeId" integer NOT NULL,
    "Discriminator" character varying(255) NOT NULL,
    "ActivityId" uuid,
    "DialogSeenLogId" uuid,
    "TransmissionId" uuid,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "LabelAssignmentLogId" uuid,
    "ActorNameEntityId" uuid
);

CREATE TABLE public."ActorName" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "ActorId" character varying(255),
    "Name" character varying(255),
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL
);

CREATE TABLE public."ActorType" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."Attachment" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Discriminator" character varying(255) NOT NULL,
    "DialogId" uuid,
    "TransmissionId" uuid
);

CREATE TABLE public."AttachmentUrl" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "MediaType" character varying(255),
    "Url" character varying(1023) NOT NULL,
    "ConsumerTypeId" integer NOT NULL,
    "AttachmentId" uuid NOT NULL
);

CREATE TABLE public."AttachmentUrlConsumerType" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."Dialog" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "Revision" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "ContentUpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Deleted" boolean NOT NULL,
    "DeletedAt" timestamp with time zone,
    "Org" character varying(255) NOT NULL COLLATE pg_catalog."C",
    "ServiceResource" character varying(255) NOT NULL COLLATE pg_catalog."C",
    "ServiceResourceType" character varying(255) NOT NULL,
    "Party" character varying(255) NOT NULL COLLATE pg_catalog."C",
    "Progress" integer,
    "ExtendedStatus" character varying(255),
    "ExternalReference" character varying(255),
    "VisibleFrom" timestamp with time zone,
    "DueAt" timestamp with time zone,
    "ExpiresAt" timestamp with time zone,
    "StatusId" integer NOT NULL,
    "PrecedingProcess" character varying(255),
    "Process" character varying(255),
    "IdempotentKey" character varying(36),
    "IsApiOnly" boolean DEFAULT false NOT NULL
);

CREATE TABLE public."DialogActivity" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "ExtendedType" character varying(1023),
    "TypeId" integer NOT NULL,
    "DialogId" uuid NOT NULL,
    "TransmissionId" uuid
);

CREATE TABLE public."DialogActivityType" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."DialogApiAction" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Action" character varying(255) NOT NULL,
    "AuthorizationAttribute" character varying(255),
    "DialogId" uuid NOT NULL,
    "Name" character varying(255)
);

CREATE TABLE public."DialogApiActionEndpoint" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Version" character varying(255),
    "Url" character varying(1023) NOT NULL,
    "DocumentationUrl" character varying(1023),
    "RequestSchema" character varying(1023),
    "ResponseSchema" character varying(1023),
    "Deprecated" boolean NOT NULL,
    "SunsetAt" timestamp with time zone,
    "HttpMethodId" integer NOT NULL,
    "ActionId" uuid NOT NULL
);

CREATE TABLE public."DialogContent" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "MediaType" character varying(255) DEFAULT ''::character varying NOT NULL,
    "DialogId" uuid NOT NULL,
    "TypeId" integer NOT NULL
);

CREATE TABLE public."DialogContentType" (
    "Id" integer NOT NULL,
    "Required" boolean NOT NULL,
    "OutputInList" boolean NOT NULL,
    "MaxLength" integer NOT NULL,
    "AllowedMediaTypes" text[] NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."DialogEndUserContext" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Revision" uuid DEFAULT gen_random_uuid() NOT NULL,
    "DialogId" uuid,
    "SystemLabelId" integer NOT NULL
);

CREATE TABLE public."DialogGuiAction" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Action" character varying(255) NOT NULL,
    "Url" character varying(1023) NOT NULL,
    "AuthorizationAttribute" character varying(255),
    "IsDeleteDialogAction" boolean NOT NULL,
    "PriorityId" integer NOT NULL,
    "HttpMethodId" integer NOT NULL,
    "DialogId" uuid NOT NULL
);

CREATE TABLE public."DialogGuiActionPriority" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."DialogSearchTag" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "Value" character varying(63) NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "DialogId" uuid NOT NULL
);

CREATE TABLE public."DialogSeenLog" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "IsViaServiceOwner" boolean DEFAULT false NOT NULL,
    "DialogId" uuid NOT NULL,
    "EndUserTypeId" integer NOT NULL
);

CREATE TABLE public."DialogServiceOwnerContext" (
    "DialogId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Revision" uuid DEFAULT gen_random_uuid() NOT NULL
);

CREATE TABLE public."DialogServiceOwnerLabel" (
    "Value" character varying(255) NOT NULL,
    "DialogServiceOwnerContextId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL
);

CREATE TABLE public."DialogStatus" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."DialogTransmission" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "AuthorizationAttribute" character varying(255),
    "ExtendedType" character varying(1023),
    "TypeId" integer NOT NULL,
    "DialogId" uuid NOT NULL,
    "RelatedTransmissionId" uuid,
    "ExternalReference" character varying(255)
);

CREATE TABLE public."DialogTransmissionContent" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "MediaType" character varying(255) DEFAULT ''::character varying NOT NULL,
    "TransmissionId" uuid NOT NULL,
    "TypeId" integer NOT NULL
);

CREATE TABLE public."DialogTransmissionContentType" (
    "Id" integer NOT NULL,
    "Required" boolean NOT NULL,
    "MaxLength" integer NOT NULL,
    "AllowedMediaTypes" text[] NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."DialogTransmissionType" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."DialogUserType" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."HttpVerb" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."LabelAssignmentLog" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "Name" character varying(255) NOT NULL,
    "Action" character varying(255) NOT NULL,
    "ContextId" uuid NOT NULL
);

CREATE TABLE public."Localization" (
    "LanguageCode" character varying(15) NOT NULL,
    "LocalizationSetId" uuid NOT NULL,
    "Value" character varying(4095) NOT NULL
);

CREATE TABLE public."LocalizationSet" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "Discriminator" character varying(255) NOT NULL,
    "DialogGuiActionPrompt_GuiActionId" uuid,
    "GuiActionId" uuid,
    "ActivityId" uuid,
    "AttachmentId" uuid,
    "DialogContentId" uuid,
    "TransmissionContentId" uuid
);

CREATE TABLE public."MassTransitInboxState" (
    "Id" bigint NOT NULL,
    "MessageId" uuid NOT NULL,
    "ConsumerId" uuid NOT NULL,
    "LockId" uuid NOT NULL,
    "RowVersion" bytea,
    "Received" timestamp with time zone NOT NULL,
    "ReceiveCount" integer NOT NULL,
    "ExpirationTime" timestamp with time zone,
    "Consumed" timestamp with time zone,
    "Delivered" timestamp with time zone,
    "LastSequenceNumber" bigint
);

ALTER TABLE public."MassTransitInboxState" ALTER COLUMN "Id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public."MassTransitInboxState_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE public."MassTransitOutboxMessage" (
    "SequenceNumber" bigint NOT NULL,
    "EnqueueTime" timestamp with time zone,
    "SentTime" timestamp with time zone NOT NULL,
    "Headers" text,
    "Properties" text,
    "InboxMessageId" uuid,
    "InboxConsumerId" uuid,
    "OutboxId" uuid,
    "MessageId" uuid NOT NULL,
    "ContentType" character varying(256) NOT NULL,
    "MessageType" text NOT NULL,
    "Body" text NOT NULL,
    "ConversationId" uuid,
    "CorrelationId" uuid,
    "InitiatorId" uuid,
    "RequestId" uuid,
    "SourceAddress" character varying(256),
    "DestinationAddress" character varying(256),
    "ResponseAddress" character varying(256),
    "FaultAddress" character varying(256),
    "ExpirationTime" timestamp with time zone
);

ALTER TABLE public."MassTransitOutboxMessage" ALTER COLUMN "SequenceNumber" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public."MassTransitOutboxMessage_SequenceNumber_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE public."MassTransitOutboxState" (
    "OutboxId" uuid NOT NULL,
    "LockId" uuid NOT NULL,
    "RowVersion" bytea,
    "Created" timestamp with time zone NOT NULL,
    "Delivered" timestamp with time zone,
    "LastSequenceNumber" bigint
);

CREATE TABLE public."NotificationAcknowledgement" (
    "EventId" uuid NOT NULL,
    "NotificationHandler" character varying(255) NOT NULL,
    "AcknowledgedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL
);

CREATE TABLE public."ResourcePolicyInformation" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "Resource" character varying(255) NOT NULL,
    "MinimumAuthenticationLevel" integer NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL
);

CREATE TABLE public."SubjectResource" (
    "Id" uuid DEFAULT gen_random_uuid() NOT NULL,
    "Subject" character varying(255) NOT NULL,
    "Resource" character varying(255) NOT NULL,
    "UpdatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL,
    "CreatedAt" timestamp with time zone DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'utc'::text) NOT NULL
);

CREATE TABLE public."SystemLabel" (
    "Id" integer NOT NULL,
    "Name" character varying(255) NOT NULL
);

CREATE TABLE public."__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL
);

ALTER TABLE ONLY public."MassTransitInboxState"
    ADD CONSTRAINT "AK_MassTransitInboxState_MessageId_ConsumerId" UNIQUE ("MessageId", "ConsumerId");

ALTER TABLE ONLY public."Actor"
    ADD CONSTRAINT "PK_Actor" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."ActorName"
    ADD CONSTRAINT "PK_ActorName" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."ActorType"
    ADD CONSTRAINT "PK_ActorType" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."Attachment"
    ADD CONSTRAINT "PK_Attachment" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."AttachmentUrl"
    ADD CONSTRAINT "PK_AttachmentUrl" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."AttachmentUrlConsumerType"
    ADD CONSTRAINT "PK_AttachmentUrlConsumerType" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."Dialog"
    ADD CONSTRAINT "PK_Dialog" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogActivity"
    ADD CONSTRAINT "PK_DialogActivity" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogActivityType"
    ADD CONSTRAINT "PK_DialogActivityType" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogApiAction"
    ADD CONSTRAINT "PK_DialogApiAction" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogApiActionEndpoint"
    ADD CONSTRAINT "PK_DialogApiActionEndpoint" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogContent"
    ADD CONSTRAINT "PK_DialogContent" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogContentType"
    ADD CONSTRAINT "PK_DialogContentType" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogEndUserContext"
    ADD CONSTRAINT "PK_DialogEndUserContext" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogGuiAction"
    ADD CONSTRAINT "PK_DialogGuiAction" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogGuiActionPriority"
    ADD CONSTRAINT "PK_DialogGuiActionPriority" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogSearchTag"
    ADD CONSTRAINT "PK_DialogSearchTag" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogSeenLog"
    ADD CONSTRAINT "PK_DialogSeenLog" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogServiceOwnerContext"
    ADD CONSTRAINT "PK_DialogServiceOwnerContext" PRIMARY KEY ("DialogId");

ALTER TABLE ONLY public."DialogServiceOwnerLabel"
    ADD CONSTRAINT "PK_DialogServiceOwnerLabel" PRIMARY KEY ("DialogServiceOwnerContextId", "Value");

ALTER TABLE ONLY public."DialogStatus"
    ADD CONSTRAINT "PK_DialogStatus" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogTransmission"
    ADD CONSTRAINT "PK_DialogTransmission" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogTransmissionContent"
    ADD CONSTRAINT "PK_DialogTransmissionContent" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogTransmissionContentType"
    ADD CONSTRAINT "PK_DialogTransmissionContentType" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogTransmissionType"
    ADD CONSTRAINT "PK_DialogTransmissionType" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."DialogUserType"
    ADD CONSTRAINT "PK_DialogUserType" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."HttpVerb"
    ADD CONSTRAINT "PK_HttpVerb" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."LabelAssignmentLog"
    ADD CONSTRAINT "PK_LabelAssignmentLog" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."Localization"
    ADD CONSTRAINT "PK_Localization" PRIMARY KEY ("LocalizationSetId", "LanguageCode");

ALTER TABLE ONLY public."LocalizationSet"
    ADD CONSTRAINT "PK_LocalizationSet" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."MassTransitInboxState"
    ADD CONSTRAINT "PK_MassTransitInboxState" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."MassTransitOutboxMessage"
    ADD CONSTRAINT "PK_MassTransitOutboxMessage" PRIMARY KEY ("SequenceNumber");

ALTER TABLE ONLY public."MassTransitOutboxState"
    ADD CONSTRAINT "PK_MassTransitOutboxState" PRIMARY KEY ("OutboxId");

ALTER TABLE ONLY public."NotificationAcknowledgement"
    ADD CONSTRAINT "PK_NotificationAcknowledgement" PRIMARY KEY ("EventId", "NotificationHandler");

ALTER TABLE ONLY public."ResourcePolicyInformation"
    ADD CONSTRAINT "PK_ResourcePolicyInformation" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."SubjectResource"
    ADD CONSTRAINT "PK_SubjectResource" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."SystemLabel"
    ADD CONSTRAINT "PK_SystemLabel" PRIMARY KEY ("Id");

ALTER TABLE ONLY public."__EFMigrationsHistory"
    ADD CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId");

CREATE UNIQUE INDEX "IX_ActorName_ActorId_Name" ON public."ActorName" USING btree ("ActorId", "Name") NULLS NOT DISTINCT;

CREATE UNIQUE INDEX "IX_Actor_ActivityId" ON public."Actor" USING btree ("ActivityId");

CREATE INDEX "IX_Actor_ActorNameEntityId" ON public."Actor" USING btree ("ActorNameEntityId");

CREATE INDEX "IX_Actor_ActorTypeId" ON public."Actor" USING btree ("ActorTypeId");

CREATE UNIQUE INDEX "IX_Actor_DialogSeenLogId" ON public."Actor" USING btree ("DialogSeenLogId");

CREATE UNIQUE INDEX "IX_Actor_LabelAssignmentLogId" ON public."Actor" USING btree ("LabelAssignmentLogId");

CREATE UNIQUE INDEX "IX_Actor_TransmissionId" ON public."Actor" USING btree ("TransmissionId");

CREATE INDEX "IX_AttachmentUrl_AttachmentId" ON public."AttachmentUrl" USING btree ("AttachmentId");

CREATE INDEX "IX_AttachmentUrl_ConsumerTypeId" ON public."AttachmentUrl" USING btree ("ConsumerTypeId");

CREATE INDEX "IX_Attachment_DialogId" ON public."Attachment" USING btree ("DialogId");

CREATE INDEX "IX_Attachment_TransmissionId" ON public."Attachment" USING btree ("TransmissionId");

CREATE INDEX "IX_DialogActivity_DialogId" ON public."DialogActivity" USING btree ("DialogId");

CREATE INDEX "IX_DialogActivity_TransmissionId" ON public."DialogActivity" USING btree ("TransmissionId");

CREATE INDEX "IX_DialogActivity_TypeId" ON public."DialogActivity" USING btree ("TypeId");

CREATE INDEX "IX_DialogApiActionEndpoint_ActionId" ON public."DialogApiActionEndpoint" USING btree ("ActionId");

CREATE INDEX "IX_DialogApiActionEndpoint_HttpMethodId" ON public."DialogApiActionEndpoint" USING btree ("HttpMethodId");

CREATE INDEX "IX_DialogApiAction_DialogId" ON public."DialogApiAction" USING btree ("DialogId");

CREATE UNIQUE INDEX "IX_DialogContent_DialogId_TypeId" ON public."DialogContent" USING btree ("DialogId", "TypeId");

CREATE INDEX "IX_DialogContent_TypeId" ON public."DialogContent" USING btree ("TypeId");

CREATE UNIQUE INDEX "IX_DialogEndUserContext_DialogId" ON public."DialogEndUserContext" USING btree ("DialogId");

CREATE INDEX "IX_DialogEndUserContext_SystemLabelId" ON public."DialogEndUserContext" USING btree ("SystemLabelId");

CREATE INDEX "IX_DialogGuiAction_DialogId" ON public."DialogGuiAction" USING btree ("DialogId");

CREATE INDEX "IX_DialogGuiAction_HttpMethodId" ON public."DialogGuiAction" USING btree ("HttpMethodId");

CREATE INDEX "IX_DialogGuiAction_PriorityId" ON public."DialogGuiAction" USING btree ("PriorityId");

CREATE INDEX "IX_DialogSearchTag_DialogId" ON public."DialogSearchTag" USING btree ("DialogId");

CREATE INDEX "IX_DialogSearchTag_Value" ON public."DialogSearchTag" USING gin ("Value" public.gin_trgm_ops);

CREATE INDEX "IX_DialogSeenLog_DialogId" ON public."DialogSeenLog" USING btree ("DialogId");

CREATE INDEX "IX_DialogSeenLog_EndUserTypeId" ON public."DialogSeenLog" USING btree ("EndUserTypeId");

CREATE UNIQUE INDEX "IX_DialogTransmissionContent_TransmissionId_TypeId" ON public."DialogTransmissionContent" USING btree ("TransmissionId", "TypeId");

CREATE INDEX "IX_DialogTransmissionContent_TypeId" ON public."DialogTransmissionContent" USING btree ("TypeId");

CREATE INDEX "IX_DialogTransmission_DialogId" ON public."DialogTransmission" USING btree ("DialogId");

CREATE INDEX "IX_DialogTransmission_RelatedTransmissionId" ON public."DialogTransmission" USING btree ("RelatedTransmissionId");

CREATE INDEX "IX_DialogTransmission_TypeId" ON public."DialogTransmission" USING btree ("TypeId");

CREATE INDEX "IX_Dialog_CreatedAt" ON public."Dialog" USING btree ("CreatedAt");

CREATE INDEX "IX_Dialog_Deleted" ON public."Dialog" USING btree ("Deleted");

CREATE INDEX "IX_Dialog_DueAt" ON public."Dialog" USING btree ("DueAt");

CREATE INDEX "IX_Dialog_ExtendedStatus" ON public."Dialog" USING btree ("ExtendedStatus");

CREATE INDEX "IX_Dialog_ExternalReference" ON public."Dialog" USING btree ("ExternalReference");

CREATE INDEX "IX_Dialog_IsApiOnly" ON public."Dialog" USING btree ("IsApiOnly");

CREATE INDEX "IX_Dialog_Org" ON public."Dialog" USING btree ("Org");

CREATE UNIQUE INDEX "IX_Dialog_Org_IdempotentKey" ON public."Dialog" USING btree ("Org", "IdempotentKey") WHERE ("IdempotentKey" IS NOT NULL);

CREATE INDEX "IX_Dialog_Party" ON public."Dialog" USING btree ("Party");

CREATE INDEX "IX_Dialog_Process" ON public."Dialog" USING btree ("Process");

CREATE INDEX "IX_Dialog_ServiceResource" ON public."Dialog" USING btree ("ServiceResource");

CREATE INDEX "IX_Dialog_StatusId" ON public."Dialog" USING btree ("StatusId");

CREATE INDEX "IX_Dialog_UpdatedAt" ON public."Dialog" USING btree ("UpdatedAt");

CREATE INDEX "IX_Dialog_ContentUpdatedAt" ON public."Dialog" USING btree ("ContentUpdatedAt");

CREATE INDEX "IX_Dialog_VisibleFrom" ON public."Dialog" USING btree ("VisibleFrom");

CREATE INDEX "IX_LabelAssignmentLog_ContextId" ON public."LabelAssignmentLog" USING btree ("ContextId");

CREATE UNIQUE INDEX "IX_LocalizationSet_ActivityId" ON public."LocalizationSet" USING btree ("ActivityId");

CREATE UNIQUE INDEX "IX_LocalizationSet_AttachmentId" ON public."LocalizationSet" USING btree ("AttachmentId");

CREATE UNIQUE INDEX "IX_LocalizationSet_DialogContentId" ON public."LocalizationSet" USING btree ("DialogContentId");

CREATE UNIQUE INDEX "IX_LocalizationSet_DialogGuiActionPrompt_GuiActionId" ON public."LocalizationSet" USING btree ("DialogGuiActionPrompt_GuiActionId");

CREATE UNIQUE INDEX "IX_LocalizationSet_GuiActionId" ON public."LocalizationSet" USING btree ("GuiActionId");

CREATE UNIQUE INDEX "IX_LocalizationSet_TransmissionContentId" ON public."LocalizationSet" USING btree ("TransmissionContentId");

CREATE INDEX "IX_Localization_Value" ON public."Localization" USING gin ("Value" public.gin_trgm_ops);

CREATE INDEX "IX_MassTransitInboxState_Delivered" ON public."MassTransitInboxState" USING btree ("Delivered");

CREATE INDEX "IX_MassTransitOutboxMessage_EnqueueTime" ON public."MassTransitOutboxMessage" USING btree ("EnqueueTime");

CREATE INDEX "IX_MassTransitOutboxMessage_ExpirationTime" ON public."MassTransitOutboxMessage" USING btree ("ExpirationTime");

CREATE UNIQUE INDEX "IX_MassTransitOutboxMessage_InboxMessageId_InboxConsumerId_Seq~" ON public."MassTransitOutboxMessage" USING btree ("InboxMessageId", "InboxConsumerId", "SequenceNumber");

CREATE UNIQUE INDEX "IX_MassTransitOutboxMessage_OutboxId_SequenceNumber" ON public."MassTransitOutboxMessage" USING btree ("OutboxId", "SequenceNumber");

CREATE INDEX "IX_MassTransitOutboxState_Created" ON public."MassTransitOutboxState" USING btree ("Created");

CREATE INDEX "IX_NotificationAcknowledgement_EventId" ON public."NotificationAcknowledgement" USING btree ("EventId");

CREATE UNIQUE INDEX "IX_ResourcePolicyInformation_Resource" ON public."ResourcePolicyInformation" USING btree ("Resource");

CREATE UNIQUE INDEX "IX_SubjectResource_Resource_Subject" ON public."SubjectResource" USING btree ("Resource", "Subject");

ALTER TABLE ONLY public."Actor"
    ADD CONSTRAINT "FK_Actor_ActorName_ActorNameEntityId" FOREIGN KEY ("ActorNameEntityId") REFERENCES public."ActorName"("Id");

ALTER TABLE ONLY public."Actor"
    ADD CONSTRAINT "FK_Actor_ActorType_ActorTypeId" FOREIGN KEY ("ActorTypeId") REFERENCES public."ActorType"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."Actor"
    ADD CONSTRAINT "FK_Actor_DialogActivity_ActivityId" FOREIGN KEY ("ActivityId") REFERENCES public."DialogActivity"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."Actor"
    ADD CONSTRAINT "FK_Actor_DialogSeenLog_DialogSeenLogId" FOREIGN KEY ("DialogSeenLogId") REFERENCES public."DialogSeenLog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."Actor"
    ADD CONSTRAINT "FK_Actor_DialogTransmission_TransmissionId" FOREIGN KEY ("TransmissionId") REFERENCES public."DialogTransmission"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."Actor"
    ADD CONSTRAINT "FK_Actor_LabelAssignmentLog_LabelAssignmentLogId" FOREIGN KEY ("LabelAssignmentLogId") REFERENCES public."LabelAssignmentLog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."AttachmentUrl"
    ADD CONSTRAINT "FK_AttachmentUrl_AttachmentUrlConsumerType_ConsumerTypeId" FOREIGN KEY ("ConsumerTypeId") REFERENCES public."AttachmentUrlConsumerType"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."AttachmentUrl"
    ADD CONSTRAINT "FK_AttachmentUrl_Attachment_AttachmentId" FOREIGN KEY ("AttachmentId") REFERENCES public."Attachment"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."Attachment"
    ADD CONSTRAINT "FK_Attachment_DialogTransmission_TransmissionId" FOREIGN KEY ("TransmissionId") REFERENCES public."DialogTransmission"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."Attachment"
    ADD CONSTRAINT "FK_Attachment_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogActivity"
    ADD CONSTRAINT "FK_DialogActivity_DialogActivityType_TypeId" FOREIGN KEY ("TypeId") REFERENCES public."DialogActivityType"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogActivity"
    ADD CONSTRAINT "FK_DialogActivity_DialogTransmission_TransmissionId" FOREIGN KEY ("TransmissionId") REFERENCES public."DialogTransmission"("Id") ON DELETE SET NULL;

ALTER TABLE ONLY public."DialogActivity"
    ADD CONSTRAINT "FK_DialogActivity_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogApiActionEndpoint"
    ADD CONSTRAINT "FK_DialogApiActionEndpoint_DialogApiAction_ActionId" FOREIGN KEY ("ActionId") REFERENCES public."DialogApiAction"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogApiActionEndpoint"
    ADD CONSTRAINT "FK_DialogApiActionEndpoint_HttpVerb_HttpMethodId" FOREIGN KEY ("HttpMethodId") REFERENCES public."HttpVerb"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogApiAction"
    ADD CONSTRAINT "FK_DialogApiAction_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogContent"
    ADD CONSTRAINT "FK_DialogContent_DialogContentType_TypeId" FOREIGN KEY ("TypeId") REFERENCES public."DialogContentType"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogContent"
    ADD CONSTRAINT "FK_DialogContent_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogEndUserContext"
    ADD CONSTRAINT "FK_DialogEndUserContext_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE SET NULL;

ALTER TABLE ONLY public."DialogEndUserContext"
    ADD CONSTRAINT "FK_DialogEndUserContext_SystemLabel_SystemLabelId" FOREIGN KEY ("SystemLabelId") REFERENCES public."SystemLabel"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogGuiAction"
    ADD CONSTRAINT "FK_DialogGuiAction_DialogGuiActionPriority_PriorityId" FOREIGN KEY ("PriorityId") REFERENCES public."DialogGuiActionPriority"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogGuiAction"
    ADD CONSTRAINT "FK_DialogGuiAction_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogGuiAction"
    ADD CONSTRAINT "FK_DialogGuiAction_HttpVerb_HttpMethodId" FOREIGN KEY ("HttpMethodId") REFERENCES public."HttpVerb"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogSearchTag"
    ADD CONSTRAINT "FK_DialogSearchTag_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogSeenLog"
    ADD CONSTRAINT "FK_DialogSeenLog_DialogUserType_EndUserTypeId" FOREIGN KEY ("EndUserTypeId") REFERENCES public."DialogUserType"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogSeenLog"
    ADD CONSTRAINT "FK_DialogSeenLog_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogServiceOwnerContext"
    ADD CONSTRAINT "FK_DialogServiceOwnerContext_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogServiceOwnerLabel"
    ADD CONSTRAINT "FK_DialogServiceOwnerLabel_DialogServiceOwnerContext_DialogSer~" FOREIGN KEY ("DialogServiceOwnerContextId") REFERENCES public."DialogServiceOwnerContext"("DialogId") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogTransmissionContent"
    ADD CONSTRAINT "FK_DialogTransmissionContent_DialogTransmissionContentType_Typ~" FOREIGN KEY ("TypeId") REFERENCES public."DialogTransmissionContentType"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogTransmissionContent"
    ADD CONSTRAINT "FK_DialogTransmissionContent_DialogTransmission_TransmissionId" FOREIGN KEY ("TransmissionId") REFERENCES public."DialogTransmission"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."DialogTransmission"
    ADD CONSTRAINT "FK_DialogTransmission_DialogTransmissionType_TypeId" FOREIGN KEY ("TypeId") REFERENCES public."DialogTransmissionType"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."DialogTransmission"
    ADD CONSTRAINT "FK_DialogTransmission_DialogTransmission_RelatedTransmissionId" FOREIGN KEY ("RelatedTransmissionId") REFERENCES public."DialogTransmission"("Id") ON DELETE SET NULL;

ALTER TABLE ONLY public."DialogTransmission"
    ADD CONSTRAINT "FK_DialogTransmission_Dialog_DialogId" FOREIGN KEY ("DialogId") REFERENCES public."Dialog"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."Dialog"
    ADD CONSTRAINT "FK_Dialog_DialogStatus_StatusId" FOREIGN KEY ("StatusId") REFERENCES public."DialogStatus"("Id") ON DELETE RESTRICT;

ALTER TABLE ONLY public."LabelAssignmentLog"
    ADD CONSTRAINT "FK_LabelAssignmentLog_DialogEndUserContext_ContextId" FOREIGN KEY ("ContextId") REFERENCES public."DialogEndUserContext"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."LocalizationSet"
    ADD CONSTRAINT "FK_LocalizationSet_Attachment_AttachmentId" FOREIGN KEY ("AttachmentId") REFERENCES public."Attachment"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."LocalizationSet"
    ADD CONSTRAINT "FK_LocalizationSet_DialogActivity_ActivityId" FOREIGN KEY ("ActivityId") REFERENCES public."DialogActivity"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."LocalizationSet"
    ADD CONSTRAINT "FK_LocalizationSet_DialogContent_DialogContentId" FOREIGN KEY ("DialogContentId") REFERENCES public."DialogContent"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."LocalizationSet"
    ADD CONSTRAINT "FK_LocalizationSet_DialogGuiAction_DialogGuiActionPrompt_GuiAc~" FOREIGN KEY ("DialogGuiActionPrompt_GuiActionId") REFERENCES public."DialogGuiAction"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."LocalizationSet"
    ADD CONSTRAINT "FK_LocalizationSet_DialogGuiAction_GuiActionId" FOREIGN KEY ("GuiActionId") REFERENCES public."DialogGuiAction"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."LocalizationSet"
    ADD CONSTRAINT "FK_LocalizationSet_DialogTransmissionContent_TransmissionConte~" FOREIGN KEY ("TransmissionContentId") REFERENCES public."DialogTransmissionContent"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."Localization"
    ADD CONSTRAINT "FK_Localization_LocalizationSet_LocalizationSetId" FOREIGN KEY ("LocalizationSetId") REFERENCES public."LocalizationSet"("Id") ON DELETE CASCADE;

ALTER TABLE ONLY public."MassTransitOutboxMessage"
    ADD CONSTRAINT "FK_MassTransitOutboxMessage_MassTransitInboxState_InboxMessage~" FOREIGN KEY ("InboxMessageId", "InboxConsumerId") REFERENCES public."MassTransitInboxState"("MessageId", "ConsumerId");

ALTER TABLE ONLY public."MassTransitOutboxMessage"
    ADD CONSTRAINT "FK_MassTransitOutboxMessage_MassTransitOutboxState_OutboxId" FOREIGN KEY ("OutboxId") REFERENCES public."MassTransitOutboxState"("OutboxId");


