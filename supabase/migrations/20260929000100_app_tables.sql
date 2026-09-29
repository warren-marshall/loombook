-- App tables, generated from the TypeORM entities (the schema synchronize built)
-- and now owned by migrations. Change the schema with a new migration; the API
-- no longer runs synchronize.

CREATE TYPE public.clients_status_enum AS ENUM ('active', 'past', 'churned');
CREATE TYPE public.lead_status_enum AS ENUM ('new', 'contacted', 'contract_sent', 'booked', 'lost', 'archived');

--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachments (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    filename character varying NOT NULL,
    url character varying NOT NULL,
    "clientId" uuid,
    "leadId" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "companyName" character varying NOT NULL,
    industry character varying,
    website character varying,
    status public.clients_status_enum DEFAULT 'active'::public.clients_status_enum NOT NULL,
    "convertedFromLeadId" character varying,
    "stripeCustomerId" character varying,
    "updatedByUserId" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contact; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    phone character varying,
    role character varying,
    "isPrimary" boolean DEFAULT false NOT NULL,
    "clientId" uuid,
    "leadId" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contracts (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    title character varying NOT NULL,
    "clientId" uuid,
    "leadId" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: email_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_messages (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    subject character varying,
    message text NOT NULL,
    "clientId" uuid,
    "leadId" uuid,
    "contactId" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "amountCents" integer NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    "clientId" uuid NOT NULL,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: lead; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lead (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "businessName" character varying NOT NULL,
    website character varying,
    status public.lead_status_enum DEFAULT 'new'::public.lead_status_enum NOT NULL,
    "updatedByUserId" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT now() NOT NULL,
    "convertedToClientId" character varying
);


--
-- Name: location; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    state character varying NOT NULL,
    "nationalPark" boolean NOT NULL,
    "nationalParkName" character varying,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT now() NOT NULL,
    coordinates extensions.geography(Point,4326) NOT NULL,
    "accuracyMeters" real,
    "updatedByUserId" uuid
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text,
    status character varying DEFAULT 'future'::character varying NOT NULL,
    "startDate" date,
    "dueDate" date,
    "expectedDuration" integer,
    "completedDate" timestamp with time zone,
    "createdById" uuid NOT NULL,
    "clientId" uuid,
    "leadId" uuid,
    "lastModifiedById" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: task_dependencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_dependencies (
    "taskId" uuid NOT NULL,
    "dependsOnTaskId" uuid NOT NULL
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text,
    status character varying DEFAULT 'future'::character varying NOT NULL,
    "projectId" uuid NOT NULL,
    "startDate" date,
    "dueDate" date,
    "expectedDuration" integer,
    "assigneeName" character varying,
    "assigneeUserId" uuid,
    "assigneeContactId" uuid,
    "isRecurring" boolean DEFAULT false NOT NULL,
    "recurrencePattern" character varying,
    "recurrenceInterval" integer,
    "recurrenceDayOfWeek" integer,
    "recurrenceEndDate" date,
    "recurrenceCount" integer,
    "recurringGroupId" uuid,
    "createdById" uuid NOT NULL,
    "lastModifiedById" uuid,
    "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT now() NOT NULL,
    "completedAt" timestamp with time zone
);


--
-- Name: contracts PK_2c7b8f3a7b1acdd49497d83d0fb; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT "PK_2c7b8f3a7b1acdd49497d83d0fb" PRIMARY KEY (id);


--
-- Name: contact PK_2cbbe00f59ab6b3bb5b8d19f989; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact
    ADD CONSTRAINT "PK_2cbbe00f59ab6b3bb5b8d19f989" PRIMARY KEY (id);


--
-- Name: attachments PK_5e1f050bcff31e3084a1d662412; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT "PK_5e1f050bcff31e3084a1d662412" PRIMARY KEY (id);


--
-- Name: projects PK_6271df0a7aed1d6c0691ce6ac50; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT "PK_6271df0a7aed1d6c0691ce6ac50" PRIMARY KEY (id);


--
-- Name: invoices PK_668cef7c22a427fd822cc1be3ce; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT "PK_668cef7c22a427fd822cc1be3ce" PRIMARY KEY (id);


--
-- Name: location PK_876d7bdba03c72251ec4c2dc827; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT "PK_876d7bdba03c72251ec4c2dc827" PRIMARY KEY (id);


--
-- Name: tasks PK_8d12ff38fcc62aaba2cab748772; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "PK_8d12ff38fcc62aaba2cab748772" PRIMARY KEY (id);


--
-- Name: email_messages PK_922cad79d5a315f5d1d06b077da; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT "PK_922cad79d5a315f5d1d06b077da" PRIMARY KEY (id);


--
-- Name: lead PK_ca96c1888f7dcfccab72b72fffa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead
    ADD CONSTRAINT "PK_ca96c1888f7dcfccab72b72fffa" PRIMARY KEY (id);


--
-- Name: clients PK_f1ab7cf3a5714dbc6bb4e1c28a4; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT "PK_f1ab7cf3a5714dbc6bb4e1c28a4" PRIMARY KEY (id);


--
-- Name: task_dependencies PK_ff11847da61cdd7f74e0f832ac0; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_dependencies
    ADD CONSTRAINT "PK_ff11847da61cdd7f74e0f832ac0" PRIMARY KEY ("taskId", "dependsOnTaskId");


--
-- Name: clients UQ_0736e47e4e77feeeebc1072bb86; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT "UQ_0736e47e4e77feeeebc1072bb86" UNIQUE ("stripeCustomerId");


--
-- Name: IDX_091f9433895a53408cb8ae3864; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_091f9433895a53408cb8ae3864" ON public.projects USING btree ("clientId");


--
-- Name: IDX_39873ca558965503fff41dc89c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_39873ca558965503fff41dc89c" ON public.location USING gist (coordinates);


--
-- Name: IDX_646afe752c665e1b454a6e0dcc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_646afe752c665e1b454a6e0dcc" ON public.projects USING btree ("leadId");


--
-- Name: IDX_70371fdc2193845ef4feb9fb87; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_70371fdc2193845ef4feb9fb87" ON public.task_dependencies USING btree ("taskId");


--
-- Name: IDX_e08fca67ca8966e6b9914bf295; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_e08fca67ca8966e6b9914bf295" ON public.tasks USING btree ("projectId");


--
-- Name: IDX_e94ede407a522714514c8471a8; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_e94ede407a522714514c8471a8" ON public.task_dependencies USING btree ("dependsOnTaskId");


--
-- Name: email_messages FK_053145c3bb6387377348b24ab1d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT "FK_053145c3bb6387377348b24ab1d" FOREIGN KEY ("leadId") REFERENCES public.lead(id) ON DELETE CASCADE;


--
-- Name: projects FK_091f9433895a53408cb8ae3864f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT "FK_091f9433895a53408cb8ae3864f" FOREIGN KEY ("clientId") REFERENCES public.clients(id) ON DELETE SET NULL;


--
-- Name: clients FK_1140b0ec88cc2d9fb8dcdd8f261; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT "FK_1140b0ec88cc2d9fb8dcdd8f261" FOREIGN KEY ("updatedByUserId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: location FK_178e42769e2b579cc63b07b3f7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT "FK_178e42769e2b579cc63b07b3f7e" FOREIGN KEY ("updatedByUserId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: tasks FK_1eb9fa3cfdd42e6e10a2f694455; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "FK_1eb9fa3cfdd42e6e10a2f694455" FOREIGN KEY ("assigneeContactId") REFERENCES public.contact(id) ON DELETE SET NULL;


--
-- Name: email_messages FK_3eff0f1cdf070ecf71bb6536fe9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT "FK_3eff0f1cdf070ecf71bb6536fe9" FOREIGN KEY ("clientId") REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: lead FK_43bdafabe101e326a45c5b78920; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead
    ADD CONSTRAINT "FK_43bdafabe101e326a45c5b78920" FOREIGN KEY ("updatedByUserId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: attachments FK_472446b0b740ce87bd8ae8ef6ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT "FK_472446b0b740ce87bd8ae8ef6ff" FOREIGN KEY ("clientId") REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: attachments FK_58759ae11d403ec1ceb76153a5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT "FK_58759ae11d403ec1ceb76153a5c" FOREIGN KEY ("leadId") REFERENCES public.lead(id) ON DELETE CASCADE;


--
-- Name: contracts FK_62a5163bebb9d95e503b01c0fb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT "FK_62a5163bebb9d95e503b01c0fb0" FOREIGN KEY ("clientId") REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: projects FK_646afe752c665e1b454a6e0dcc0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT "FK_646afe752c665e1b454a6e0dcc0" FOREIGN KEY ("leadId") REFERENCES public.lead(id) ON DELETE SET NULL;


--
-- Name: tasks FK_660898d912c6e71107e9ef8f38d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "FK_660898d912c6e71107e9ef8f38d" FOREIGN KEY ("createdById") REFERENCES public."user"(id);


--
-- Name: task_dependencies FK_70371fdc2193845ef4feb9fb879; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_dependencies
    ADD CONSTRAINT "FK_70371fdc2193845ef4feb9fb879" FOREIGN KEY ("taskId") REFERENCES public.tasks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: email_messages FK_7d0fb3250b2c909c1801a5a7793; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT "FK_7d0fb3250b2c909c1801a5a7793" FOREIGN KEY ("contactId") REFERENCES public.contact(id) ON DELETE SET NULL;


--
-- Name: tasks FK_98c6a17944b26a7fe56ae3db440; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "FK_98c6a17944b26a7fe56ae3db440" FOREIGN KEY ("lastModifiedById") REFERENCES public."user"(id);


--
-- Name: contact FK_9bc375c83ab8f579ca1175156b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact
    ADD CONSTRAINT "FK_9bc375c83ab8f579ca1175156b4" FOREIGN KEY ("leadId") REFERENCES public.lead(id) ON DELETE CASCADE;


--
-- Name: projects FK_c4374151331fb81be8af7d0d24a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT "FK_c4374151331fb81be8af7d0d24a" FOREIGN KEY ("lastModifiedById") REFERENCES public."user"(id);


--
-- Name: tasks FK_cb46e410f6ab1216282d0c573d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "FK_cb46e410f6ab1216282d0c573d0" FOREIGN KEY ("assigneeUserId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: contracts FK_ce832f8af5c978f5e7706768b43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT "FK_ce832f8af5c978f5e7706768b43" FOREIGN KEY ("leadId") REFERENCES public.lead(id) ON DELETE CASCADE;


--
-- Name: invoices FK_d9df936180710f9968da7cf4a51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT "FK_d9df936180710f9968da7cf4a51" FOREIGN KEY ("clientId") REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: tasks FK_e08fca67ca8966e6b9914bf2956; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT "FK_e08fca67ca8966e6b9914bf2956" FOREIGN KEY ("projectId") REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: task_dependencies FK_e94ede407a522714514c8471a81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_dependencies
    ADD CONSTRAINT "FK_e94ede407a522714514c8471a81" FOREIGN KEY ("dependsOnTaskId") REFERENCES public.tasks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: contact FK_e99f8e5bcbccaec7b0b7ed65526; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact
    ADD CONSTRAINT "FK_e99f8e5bcbccaec7b0b7ed65526" FOREIGN KEY ("clientId") REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: projects FK_f55144dc92df43cd1dad5d29b90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT "FK_f55144dc92df43cd1dad5d29b90" FOREIGN KEY ("createdById") REFERENCES public."user"(id);


--
-- PostgreSQL database dump complete
--

-- Data access goes through the NestJS API (direct Postgres connection), so keep
-- these closed to PostgREST's anon/authenticated roles.
alter table public."attachments" enable row level security;
alter table public."clients" enable row level security;
alter table public."contact" enable row level security;
alter table public."contracts" enable row level security;
alter table public."email_messages" enable row level security;
alter table public."invoices" enable row level security;
alter table public."lead" enable row level security;
alter table public."location" enable row level security;
alter table public."projects" enable row level security;
alter table public."task_dependencies" enable row level security;
alter table public."tasks" enable row level security;
