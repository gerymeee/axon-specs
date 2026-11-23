-- Axon MVP baseline v1.0.0. Apply as the Supabase project database owner.
-- Supabase Auth owns Google sign-in. axon-api validates the access token and
-- maps its subject with axon_register, then supplies the resulting account UUID
-- as p_actor. The service-role credential and p_actor stay on the backend.
-- Bootstrap staff roles via trusted SQL after registration. Auth clients have
-- no direct SQL access. Keep the axon schema out of API Exposed Schemas.
BEGIN;

CREATE SCHEMA IF NOT EXISTS axon;

CREATE TABLE IF NOT EXISTS axon.route (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE CHECK (btrim(code) <> ''),
    name text NOT NULL CHECK (btrim(name) <> ''),
    enabled boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS axon.account (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    -- Detach deleted Auth identities without orphaning moderation records.
    auth_user_uuid uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    roles text[] NOT NULL DEFAULT ARRAY['passenger']::text[]
        CHECK (cardinality(roles) > 0 AND array_position(roles, NULL) IS NULL
            AND roles <@ ARRAY['system_admin', 'admin', 'moderator', 'driver', 'passenger']),
    -- A saved preference can become ineligible. Read-time eligibility is authoritative.
    primary_route_uuid uuid REFERENCES axon.route(uuid),
    driver_verified_at timestamptz,
    driver_verified_by_uuid uuid REFERENCES axon.account(uuid),
    suspended_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((driver_verified_at IS NULL) = (driver_verified_by_uuid IS NULL))
);

CREATE TABLE IF NOT EXISTS axon.driver_route (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    driver_uuid uuid NOT NULL REFERENCES axon.account(uuid),
    route_uuid uuid NOT NULL REFERENCES axon.route(uuid),
    assigned_by_uuid uuid NOT NULL REFERENCES axon.account(uuid),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    archived_at timestamptz
);
CREATE UNIQUE INDEX IF NOT EXISTS driver_route_live_pair
    ON axon.driver_route (driver_uuid, route_uuid) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS driver_route_live_route
    ON axon.driver_route (route_uuid, driver_uuid) WHERE archived_at IS NULL;

CREATE TABLE IF NOT EXISTS axon.waiting_request (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Minted by the passenger app and reused on network retries.
    uuid uuid NOT NULL UNIQUE,
    passenger_uuid uuid NOT NULL REFERENCES axon.account(uuid),
    route_uuid uuid NOT NULL REFERENCES axon.route(uuid),
    latitude double precision,
    longitude double precision,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    expires_at timestamptz NOT NULL CHECK (expires_at > created_at),
    closed_at timestamptz,
    close_reason text CHECK (close_reason IN (
        'cancelled', 'completed', 'expired', 'route_disabled', 'passenger_unavailable'
    )),
    pickup_prompt_uuid uuid UNIQUE,
    pickup_driver_uuid uuid REFERENCES axon.account(uuid),
    pickup_expires_at timestamptz,
    completed_driver_uuid uuid REFERENCES axon.account(uuid),
    CHECK ((closed_at IS NULL) = (close_reason IS NULL)),
    CHECK ((completed_driver_uuid IS NOT NULL) = (close_reason IS NOT DISTINCT FROM 'completed')),
    CHECK (
        (closed_at IS NULL AND latitude IS NOT NULL AND longitude IS NOT NULL
            AND latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
        OR (closed_at IS NOT NULL AND latitude IS NULL AND longitude IS NULL)
    ),
    CHECK (
        (pickup_prompt_uuid IS NULL AND pickup_driver_uuid IS NULL AND pickup_expires_at IS NULL)
        OR (closed_at IS NULL AND pickup_prompt_uuid IS NOT NULL AND pickup_driver_uuid IS NOT NULL
            AND pickup_expires_at IS NOT NULL AND pickup_expires_at < expires_at)
    )
);
CREATE UNIQUE INDEX IF NOT EXISTS waiting_request_one_open
    ON axon.waiting_request (passenger_uuid) WHERE closed_at IS NULL;
CREATE INDEX IF NOT EXISTS waiting_request_route_open
    ON axon.waiting_request (route_uuid, expires_at) WHERE closed_at IS NULL;
CREATE INDEX IF NOT EXISTS waiting_request_expiry_open
    ON axon.waiting_request (expires_at) WHERE closed_at IS NULL;
CREATE INDEX IF NOT EXISTS waiting_request_prompt_open
    ON axon.waiting_request (pickup_expires_at) WHERE pickup_prompt_uuid IS NOT NULL;

CREATE TABLE IF NOT EXISTS axon.misuse_report (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    request_uuid uuid NOT NULL REFERENCES axon.waiting_request(uuid),
    reporter_uuid uuid NOT NULL REFERENCES axon.account(uuid),
    subject_uuid uuid NOT NULL REFERENCES axon.account(uuid),
    reason text NOT NULL CHECK (reason IN (
        'false_waiting_pin', 'false_pickup', 'unsafe_conduct', 'other'
    )),
    created_at timestamptz NOT NULL DEFAULT now(),
    reviewed_at timestamptz,
    reviewed_by_uuid uuid REFERENCES axon.account(uuid),
    CHECK (reporter_uuid <> subject_uuid),
    CHECK ((reviewed_at IS NULL) = (reviewed_by_uuid IS NULL)),
    UNIQUE (request_uuid, reporter_uuid, subject_uuid, reason)
);
CREATE INDEX IF NOT EXISTS misuse_report_unreviewed
    ON axon.misuse_report (created_at) WHERE reviewed_at IS NULL;

CREATE TABLE IF NOT EXISTS axon.moderation_action (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    subject_uuid uuid NOT NULL REFERENCES axon.account(uuid),
    moderator_uuid uuid NOT NULL REFERENCES axon.account(uuid),
    report_uuid uuid REFERENCES axon.misuse_report(uuid),
    action text NOT NULL CHECK (action IN ('suspend', 'restore')),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS moderation_action_subject
    ON axon.moderation_action (subject_uuid, created_at);

-- All Axon relations are created in order through online operations. Their
-- UUID references can therefore be enforced without constraining offline drafts.
CREATE OR REPLACE FUNCTION axon.has_role(p_actor uuid, p_role text)
RETURNS boolean LANGUAGE sql STABLE SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM axon.account a WHERE a.uuid = p_actor
          AND a.auth_user_uuid IS NOT NULL AND a.suspended_at IS NULL
          AND p_role = ANY (a.roles)
    );
$$;

CREATE OR REPLACE FUNCTION axon.driver_can_serve(p_driver uuid, p_route uuid)
RETURNS boolean LANGUAGE sql STABLE SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM axon.driver_route d
        JOIN axon.route r ON r.uuid = d.route_uuid
        JOIN axon.account a ON a.uuid = d.driver_uuid
        WHERE d.driver_uuid = p_driver AND d.route_uuid = p_route
          AND d.archived_at IS NULL AND r.enabled
          AND a.auth_user_uuid IS NOT NULL AND a.suspended_at IS NULL
          AND a.driver_verified_at IS NOT NULL AND 'driver' = ANY (a.roles)
    );
$$;

-- A row stays as a coordinate-free outcome/report reference when it closes.
-- Time and access filters also apply at read time, even if maintenance is delayed.
CREATE OR REPLACE FUNCTION axon.reap_waiting(p_passenger uuid, p_request uuid)
RETURNS void LANGUAGE plpgsql SET search_path = ''
AS $$
DECLARE
    v_now timestamptz := clock_timestamp();
BEGIN
    UPDATE axon.waiting_request w
       SET closed_at = v_now, updated_at = v_now,
           close_reason = CASE WHEN w.expires_at <= v_now THEN 'expired'
                               WHEN NOT r.enabled THEN 'route_disabled'
                               ELSE 'passenger_unavailable' END,
           latitude = NULL, longitude = NULL, pickup_prompt_uuid = NULL,
           pickup_driver_uuid = NULL, pickup_expires_at = NULL
      FROM axon.route r, axon.account a
     WHERE w.route_uuid = r.uuid AND w.passenger_uuid = a.uuid AND w.closed_at IS NULL
       AND (p_passenger IS NULL OR w.passenger_uuid = p_passenger)
       AND (p_request IS NULL OR w.uuid = p_request)
       AND (w.expires_at <= v_now OR NOT r.enabled OR a.suspended_at IS NOT NULL
            OR a.auth_user_uuid IS NULL OR NOT ('passenger' = ANY (a.roles)));

    UPDATE axon.waiting_request w
       SET pickup_prompt_uuid = NULL, pickup_driver_uuid = NULL, pickup_expires_at = NULL,
           updated_at = v_now
     WHERE w.closed_at IS NULL AND w.pickup_prompt_uuid IS NOT NULL
       AND (p_passenger IS NULL OR w.passenger_uuid = p_passenger)
       AND (p_request IS NULL OR w.uuid = p_request)
       AND (w.pickup_expires_at <= v_now OR NOT axon.driver_can_serve(w.pickup_driver_uuid, w.route_uuid));
END;
$$;

CREATE OR REPLACE FUNCTION axon.request_state(p_request axon.waiting_request)
RETURNS jsonb LANGUAGE sql VOLATILE SET search_path = ''
AS $$
    SELECT jsonb_build_object(
        'uuid', p_request.uuid, 'route_uuid', p_request.route_uuid,
        'expires_at', p_request.expires_at, 'closed_at', p_request.closed_at,
        'status', COALESCE(p_request.close_reason,
            CASE WHEN prompt.active THEN 'pickup_pending' ELSE 'waiting' END),
        'pickup_prompt_uuid', CASE WHEN prompt.active THEN p_request.pickup_prompt_uuid END,
        'pickup_expires_at', CASE WHEN prompt.active THEN p_request.pickup_expires_at END
    )
    FROM (
        SELECT p_request.pickup_expires_at > clock_timestamp()
               AND axon.driver_can_serve(p_request.pickup_driver_uuid, p_request.route_uuid) AS active
    ) prompt;
$$;

-- Only these public RPCs are exposed to the trusted backend; they project UUIDs
-- and the fields needed by their respective workflows, never database IDs.
CREATE OR REPLACE FUNCTION public.axon_register(p_auth_user_uuid uuid, p_request_driver boolean DEFAULT false)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_account axon.account;
BEGIN
    IF p_auth_user_uuid IS NULL OR NOT EXISTS (
        SELECT 1 FROM auth.users u WHERE u.id = p_auth_user_uuid
    ) THEN
        RAISE EXCEPTION 'axon_auth_user_required' USING ERRCODE = '42501';
    END IF;
    INSERT INTO axon.account (auth_user_uuid)
    VALUES (p_auth_user_uuid) ON CONFLICT (auth_user_uuid) DO NOTHING;
    IF p_request_driver THEN
        UPDATE axon.account
           SET roles = array_append(roles, 'driver'), updated_at = clock_timestamp()
         WHERE auth_user_uuid = p_auth_user_uuid AND suspended_at IS NULL
           AND NOT ('driver' = ANY (roles));
    END IF;
    SELECT * INTO STRICT v_account FROM axon.account WHERE auth_user_uuid = p_auth_user_uuid;
    RETURN jsonb_build_object(
        'uuid', v_account.uuid, 'roles', v_account.roles,
        'primary_route_uuid', v_account.primary_route_uuid,
        'driver_verified', v_account.driver_verified_at IS NOT NULL,
        'suspended', v_account.suspended_at IS NOT NULL
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_routes(p_actor uuid, p_as_driver boolean)
RETURNS TABLE (uuid uuid, code text, name text) LANGUAGE sql STABLE
SECURITY DEFINER SET search_path = ''
AS $$
    SELECT r.uuid, r.code, r.name FROM axon.route r
    WHERE r.enabled AND CASE WHEN p_as_driver THEN axon.driver_can_serve(p_actor, r.uuid)
                             ELSE p_as_driver = false AND axon.has_role(p_actor, 'passenger') END
    ORDER BY r.name, r.code;
$$;

CREATE OR REPLACE FUNCTION public.axon_set_primary_route(p_actor uuid, p_route uuid, p_as_driver boolean)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    IF p_as_driver IS NULL OR NOT EXISTS (SELECT 1 FROM public.axon_routes(p_actor, p_as_driver) r WHERE r.uuid = p_route) THEN
        RAISE EXCEPTION 'axon_route_unavailable' USING ERRCODE = '42501';
    END IF;
    UPDATE axon.account SET primary_route_uuid = p_route, updated_at = clock_timestamp() WHERE uuid = p_actor;
    RETURN p_route;
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_start_waiting(
    p_actor uuid, p_request uuid, p_route uuid, p_latitude double precision, p_longitude double precision
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request axon.waiting_request;
    v_now timestamptz;
    v_route_enabled boolean;
BEGIN
    -- Serialize starts for this passenger and prevent a start during suspension or route shutdown.
    PERFORM 1 FROM axon.account WHERE uuid = p_actor FOR NO KEY UPDATE;
    IF NOT axon.has_role(p_actor, 'passenger') THEN
        RAISE EXCEPTION 'axon_passenger_required' USING ERRCODE = '42501';
    END IF;
    SELECT enabled INTO v_route_enabled FROM axon.route WHERE uuid = p_route FOR SHARE;
    PERFORM axon.reap_waiting(p_actor, NULL);
    SELECT * INTO v_request FROM axon.waiting_request
    WHERE uuid = p_request AND passenger_uuid = p_actor;
    IF FOUND THEN
        RETURN axon.request_state(v_request);
    END IF;
    SELECT * INTO v_request FROM axon.waiting_request
    WHERE passenger_uuid = p_actor AND closed_at IS NULL;
    IF FOUND THEN
        RETURN axon.request_state(v_request);
    END IF;
    IF v_route_enabled IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'axon_route_unavailable' USING ERRCODE = '42501';
    END IF;
    v_now := clock_timestamp();
    INSERT INTO axon.waiting_request (
        uuid, passenger_uuid, route_uuid, latitude, longitude, created_at, updated_at, expires_at
    ) VALUES (p_request, p_actor, p_route, p_latitude, p_longitude, v_now, v_now, v_now + interval '15 minutes')
    RETURNING * INTO v_request;
    RETURN axon.request_state(v_request);
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_my_waiting(p_actor uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request axon.waiting_request;
BEGIN
    IF NOT axon.has_role(p_actor, 'passenger') THEN
        RAISE EXCEPTION 'axon_passenger_required' USING ERRCODE = '42501';
    END IF;
    PERFORM axon.reap_waiting(p_actor, NULL);
    SELECT * INTO v_request FROM axon.waiting_request
    WHERE passenger_uuid = p_actor AND closed_at IS NULL AND expires_at > clock_timestamp();
    IF NOT FOUND THEN RETURN NULL; END IF;
    RETURN axon.request_state(v_request);
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_driver_map(p_actor uuid, p_route uuid)
RETURNS TABLE (
    uuid uuid, latitude double precision, longitude double precision,
    status text, expires_at timestamptz, pickup_expires_at timestamptz
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT w.uuid, w.latitude, w.longitude,
           CASE WHEN p.pending THEN 'pickup_pending' ELSE 'waiting' END,
           w.expires_at, CASE WHEN p.pending THEN w.pickup_expires_at END
    FROM axon.waiting_request w
    CROSS JOIN LATERAL (SELECT w.pickup_expires_at > statement_timestamp()
                              AND axon.driver_can_serve(w.pickup_driver_uuid, w.route_uuid) AS pending) p
    WHERE w.route_uuid = p_route AND w.closed_at IS NULL AND w.expires_at > statement_timestamp()
      AND axon.driver_can_serve(p_actor, p_route) AND axon.has_role(w.passenger_uuid, 'passenger');
$$;

CREATE OR REPLACE FUNCTION public.axon_begin_pickup(
    p_actor uuid, p_route uuid, p_request uuid, p_safely_stopped boolean,
    p_latitude double precision, p_longitude double precision, p_fix_at timestamptz,
    p_max_distance_m double precision, p_response_seconds integer
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request axon.waiting_request;
    v_now timestamptz;
    v_prompt_expires timestamptz;
    v_haversine double precision;
BEGIN
    IF NOT axon.driver_can_serve(p_actor, p_route) THEN
        RAISE EXCEPTION 'axon_route_unavailable' USING ERRCODE = '42501';
    END IF;
    -- Match and lock the requested route's row. Never expose another route's request.
    SELECT * INTO v_request FROM axon.waiting_request
    WHERE uuid = p_request AND route_uuid = p_route FOR UPDATE;
    IF NOT FOUND THEN RETURN NULL; END IF;
    PERFORM axon.reap_waiting(NULL, p_request);
    SELECT * INTO STRICT v_request FROM axon.waiting_request WHERE uuid = p_request;
    v_now := clock_timestamp();

    IF v_request.closed_at IS NOT NULL OR v_request.expires_at <= v_now
       OR NOT axon.driver_can_serve(p_actor, p_route)
       OR NOT axon.has_role(v_request.passenger_uuid, 'passenger')
       OR v_request.passenger_uuid = p_actor THEN
        RETURN NULL;
    END IF;
    IF v_request.pickup_prompt_uuid IS NOT NULL AND v_request.pickup_expires_at > v_now THEN
        IF v_request.pickup_driver_uuid = p_actor THEN
            RETURN axon.request_state(v_request);
        END IF;
        RETURN NULL;
    END IF;

    -- Threshold and response window are trusted backend configuration.
    -- Driver coordinates are used for this calculation and never stored.
    IF p_safely_stopped IS DISTINCT FROM true
       OR (p_latitude BETWEEN -90 AND 90) IS DISTINCT FROM true
       OR (p_longitude BETWEEN -180 AND 180) IS DISTINCT FROM true
       OR (p_fix_at BETWEEN v_now - interval '60 seconds' AND v_now) IS DISTINCT FROM true
       OR (p_max_distance_m > 0 AND p_max_distance_m < 'Infinity'::double precision) IS DISTINCT FROM true
       OR (p_response_seconds BETWEEN 1 AND 899) IS DISTINCT FROM true THEN
        RETURN NULL;
    END IF;
    v_prompt_expires := v_now + make_interval(secs => p_response_seconds);
    IF v_prompt_expires >= v_request.expires_at THEN RETURN NULL; END IF;

    v_haversine := power(sin(radians(p_latitude - v_request.latitude) / 2), 2)
        + cos(radians(v_request.latitude)) * cos(radians(p_latitude))
        * power(sin(radians(p_longitude - v_request.longitude) / 2), 2);
    IF 12742000 * asin(sqrt(least(1.0::double precision, v_haversine))) > p_max_distance_m THEN
        RETURN NULL;
    END IF;

    UPDATE axon.waiting_request
       SET pickup_driver_uuid = p_actor, pickup_prompt_uuid = gen_random_uuid(),
           pickup_expires_at = v_prompt_expires, updated_at = v_now
     WHERE uuid = p_request RETURNING * INTO v_request;
    RETURN axon.request_state(v_request);
END;
$$;

-- Respond using the exact prompt UUID. A delayed response for an old prompt
-- cannot complete a later prompt on the same request.
CREATE OR REPLACE FUNCTION public.axon_respond_pickup(
    p_actor uuid, p_request uuid, p_prompt uuid, p_confirm boolean
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request axon.waiting_request;
    v_now timestamptz;
BEGIN
    IF NOT axon.has_role(p_actor, 'passenger') OR p_prompt IS NULL OR p_confirm IS NULL THEN
        RETURN NULL;
    END IF;
    SELECT * INTO v_request FROM axon.waiting_request
    WHERE uuid = p_request AND passenger_uuid = p_actor FOR UPDATE;
    IF NOT FOUND THEN RETURN NULL; END IF;
    PERFORM axon.reap_waiting(p_actor, p_request);
    SELECT * INTO STRICT v_request FROM axon.waiting_request WHERE uuid = p_request;
    v_now := clock_timestamp();
    IF v_request.closed_at IS NOT NULL OR v_request.expires_at <= v_now
       OR v_request.pickup_prompt_uuid IS DISTINCT FROM p_prompt OR v_request.pickup_expires_at <= v_now
       OR NOT axon.has_role(p_actor, 'passenger')
       OR NOT axon.driver_can_serve(v_request.pickup_driver_uuid, v_request.route_uuid) THEN
        RETURN NULL;
    END IF;

    UPDATE axon.waiting_request
       SET pickup_prompt_uuid = NULL, pickup_driver_uuid = NULL, pickup_expires_at = NULL,
           updated_at = v_now,
           closed_at = CASE WHEN p_confirm THEN v_now END,
           close_reason = CASE WHEN p_confirm THEN 'completed' END,
           completed_driver_uuid = CASE WHEN p_confirm THEN v_request.pickup_driver_uuid END,
           latitude = CASE WHEN NOT p_confirm THEN latitude END,
           longitude = CASE WHEN NOT p_confirm THEN longitude END
     WHERE uuid = p_request RETURNING * INTO v_request;
    RETURN axon.request_state(v_request);
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_cancel_waiting(p_actor uuid, p_request uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request axon.waiting_request;
    v_now timestamptz;
BEGIN
    IF NOT axon.has_role(p_actor, 'passenger') THEN RETURN NULL; END IF;
    SELECT * INTO v_request FROM axon.waiting_request
    WHERE uuid = p_request AND passenger_uuid = p_actor FOR UPDATE;
    IF NOT FOUND THEN RETURN NULL; END IF;
    PERFORM axon.reap_waiting(p_actor, p_request);
    SELECT * INTO STRICT v_request FROM axon.waiting_request WHERE uuid = p_request;
    IF v_request.closed_at IS NOT NULL THEN RETURN axon.request_state(v_request); END IF;
    v_now := clock_timestamp();
    UPDATE axon.waiting_request
       SET closed_at = v_now, updated_at = v_now,
           close_reason = CASE WHEN expires_at <= v_now THEN 'expired' ELSE 'cancelled' END,
           latitude = NULL, longitude = NULL, pickup_prompt_uuid = NULL,
           pickup_driver_uuid = NULL, pickup_expires_at = NULL
     WHERE uuid = p_request RETURNING * INTO v_request;
    RETURN axon.request_state(v_request);
END;
$$;

-- Schedule this with Supabase Cron before the pilot so expired coordinates are
-- cleared even when nobody is connected. The map always filters by expiry.
CREATE OR REPLACE FUNCTION public.axon_expire_waiting()
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = ''
AS $$
    SELECT axon.reap_waiting(NULL, NULL);
$$;

CREATE OR REPLACE FUNCTION public.axon_admin_routes(p_actor uuid)
RETURNS TABLE (uuid uuid, code text, name text, enabled boolean) LANGUAGE sql STABLE
SECURITY DEFINER SET search_path = ''
AS $$
    SELECT r.uuid, r.code, r.name, r.enabled FROM axon.route r
    WHERE axon.has_role(p_actor, 'admin') ORDER BY r.name, r.code;
$$;

CREATE OR REPLACE FUNCTION public.axon_admin_drivers(p_actor uuid)
RETURNS TABLE (uuid uuid, verified boolean, suspended boolean, route_uuids uuid[]) LANGUAGE sql STABLE
SECURITY DEFINER SET search_path = ''
AS $$
    SELECT a.uuid, a.driver_verified_at IS NOT NULL, a.suspended_at IS NOT NULL,
           ARRAY(SELECT d.route_uuid FROM axon.driver_route d
                 WHERE d.driver_uuid = a.uuid AND d.archived_at IS NULL ORDER BY d.route_uuid)
    FROM axon.account a
    WHERE axon.has_role(p_actor, 'admin') AND 'driver' = ANY(a.roles) AND a.auth_user_uuid IS NOT NULL;
$$;

CREATE OR REPLACE FUNCTION public.axon_save_route(
    p_actor uuid, p_route uuid, p_code text, p_name text, p_enabled boolean
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_route uuid;
BEGIN
    IF NOT axon.has_role(p_actor, 'admin') THEN
        RAISE EXCEPTION 'axon_admin_required' USING ERRCODE = '42501';
    END IF;
    INSERT INTO axon.route (uuid, code, name, enabled)
    VALUES (p_route, p_code, p_name, p_enabled)
    ON CONFLICT (uuid) DO UPDATE
      SET code = EXCLUDED.code, name = EXCLUDED.name, enabled = EXCLUDED.enabled,
          updated_at = clock_timestamp()
    RETURNING uuid INTO v_route;
    IF NOT p_enabled THEN PERFORM axon.reap_waiting(NULL, NULL); END IF;
    RETURN v_route;
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_verify_driver(p_actor uuid, p_driver uuid, p_verified boolean)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    IF NOT axon.has_role(p_actor, 'admin') OR p_verified IS NULL THEN
        RAISE EXCEPTION 'axon_admin_required' USING ERRCODE = '42501';
    END IF;
    UPDATE axon.account
       SET driver_verified_at = CASE WHEN p_verified THEN clock_timestamp() END,
           driver_verified_by_uuid = CASE WHEN p_verified THEN p_actor END, updated_at = clock_timestamp()
     WHERE uuid = p_driver AND auth_user_uuid IS NOT NULL AND 'driver' = ANY (roles)
       AND (driver_verified_at IS NOT NULL) <> p_verified;
    IF NOT FOUND THEN RETURN false; END IF;
    IF NOT p_verified THEN PERFORM axon.reap_waiting(NULL, NULL); END IF;
    RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_assign_driver(p_actor uuid, p_driver uuid, p_route uuid, p_assign boolean)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    IF NOT axon.has_role(p_actor, 'admin') OR p_assign IS NULL THEN
        RAISE EXCEPTION 'axon_admin_required' USING ERRCODE = '42501';
    END IF;
    IF p_assign THEN
        PERFORM 1 FROM axon.route WHERE uuid = p_route AND enabled FOR SHARE;
        IF NOT FOUND OR NOT EXISTS (
            SELECT 1 FROM axon.account a WHERE a.uuid = p_driver
              AND 'driver' = ANY (a.roles) AND a.driver_verified_at IS NOT NULL
              AND a.auth_user_uuid IS NOT NULL AND a.suspended_at IS NULL
        ) THEN RETURN false; END IF;
        INSERT INTO axon.driver_route (driver_uuid, route_uuid, assigned_by_uuid)
        VALUES (p_driver, p_route, p_actor)
        ON CONFLICT (driver_uuid, route_uuid) WHERE archived_at IS NULL DO NOTHING;
    ELSE
        UPDATE axon.driver_route SET archived_at = clock_timestamp(), updated_at = clock_timestamp()
        WHERE driver_uuid = p_driver AND route_uuid = p_route AND archived_at IS NULL;
        IF FOUND THEN PERFORM axon.reap_waiting(NULL, NULL); END IF;
    END IF;
    RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_report_misuse(
    p_actor uuid, p_request uuid, p_as_driver boolean, p_reason text, p_active_route uuid DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request axon.waiting_request;
    v_subject uuid;
    v_report uuid;
BEGIN
    IF p_request IS NULL OR p_as_driver IS NULL THEN RETURN NULL; END IF;
    PERFORM axon.reap_waiting(NULL, p_request);
    SELECT * INTO v_request FROM axon.waiting_request WHERE uuid = p_request;
    IF NOT FOUND THEN RETURN NULL; END IF;

    IF p_as_driver AND p_active_route = v_request.route_uuid
       AND axon.driver_can_serve(p_actor, v_request.route_uuid)
       AND (v_request.closed_at IS NULL AND v_request.expires_at > clock_timestamp()
            OR v_request.completed_driver_uuid = p_actor) THEN
        v_subject := v_request.passenger_uuid;
    ELSIF NOT p_as_driver AND v_request.passenger_uuid = p_actor
       AND axon.has_role(p_actor, 'passenger') THEN
        v_subject := COALESCE(v_request.pickup_driver_uuid, v_request.completed_driver_uuid);
    END IF;
    IF v_subject IS NULL OR v_subject = p_actor THEN RETURN NULL; END IF;

    INSERT INTO axon.misuse_report (request_uuid, reporter_uuid, subject_uuid, reason)
    VALUES (p_request, p_actor, v_subject, p_reason)
    ON CONFLICT (request_uuid, reporter_uuid, subject_uuid, reason) DO NOTHING
    RETURNING uuid INTO v_report;
    IF v_report IS NULL THEN
        SELECT uuid INTO v_report FROM axon.misuse_report
        WHERE request_uuid = p_request AND reporter_uuid = p_actor AND subject_uuid = v_subject AND reason = p_reason;
    END IF;
    RETURN v_report;
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_moderation_queue(p_actor uuid)
RETURNS TABLE (
    uuid uuid, request_uuid uuid, reporter_uuid uuid, subject_uuid uuid, reason text,
    created_at timestamptz, reviewed_at timestamptz, reviewed_by_uuid uuid, subject_suspended boolean
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT m.uuid, m.request_uuid, m.reporter_uuid, m.subject_uuid, m.reason,
           m.created_at, m.reviewed_at, m.reviewed_by_uuid, a.suspended_at IS NOT NULL
    FROM axon.misuse_report m
    JOIN axon.account a ON a.uuid = m.subject_uuid
    WHERE axon.has_role(p_actor, 'moderator')
    ORDER BY (m.reviewed_at IS NOT NULL), m.created_at, m.uuid;
$$;

CREATE OR REPLACE FUNCTION public.axon_review_report(p_actor uuid, p_report uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    IF NOT axon.has_role(p_actor, 'moderator') THEN
        RAISE EXCEPTION 'axon_moderator_required' USING ERRCODE = '42501';
    END IF;
    UPDATE axon.misuse_report SET reviewed_at = clock_timestamp(), reviewed_by_uuid = p_actor
    WHERE uuid = p_report AND reviewed_at IS NULL;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.axon_set_restriction(
    p_actor uuid, p_subject uuid, p_suspend boolean, p_report uuid DEFAULT NULL
)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
    IF NOT axon.has_role(p_actor, 'moderator') OR p_suspend IS NULL THEN
        RAISE EXCEPTION 'axon_moderator_required' USING ERRCODE = '42501';
    END IF;
    IF p_report IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM axon.misuse_report WHERE uuid = p_report AND subject_uuid = p_subject
    ) THEN RETURN false; END IF;

    UPDATE axon.account
       SET suspended_at = CASE WHEN p_suspend THEN clock_timestamp() END, updated_at = clock_timestamp()
     WHERE uuid = p_subject AND auth_user_uuid IS NOT NULL
       AND NOT (roles && ARRAY['system_admin', 'admin', 'moderator'])
       AND (suspended_at IS NOT NULL) <> p_suspend;
    IF NOT FOUND THEN RETURN false; END IF;

    INSERT INTO axon.moderation_action (subject_uuid, moderator_uuid, report_uuid, action)
    VALUES (p_subject, p_actor, p_report, CASE WHEN p_suspend THEN 'suspend' ELSE 'restore' END);
    IF p_suspend THEN PERFORM axon.reap_waiting(NULL, NULL); END IF;
    RETURN true;
END;
$$;

-- The Supabase API roles have no access to the private base tables and helpers.
-- Explicit grants avoid relying on project-specific Supabase defaults.
REVOKE ALL ON SCHEMA axon FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON ALL TABLES IN SCHEMA axon FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA axon FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA axon FROM PUBLIC, anon, authenticated, service_role;

ALTER TABLE axon.route ENABLE ROW LEVEL SECURITY;
ALTER TABLE axon.account ENABLE ROW LEVEL SECURITY;
ALTER TABLE axon.driver_route ENABLE ROW LEVEL SECURITY;
ALTER TABLE axon.waiting_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE axon.misuse_report ENABLE ROW LEVEL SECURITY;
ALTER TABLE axon.moderation_action ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    v_signature text;
BEGIN
    FOREACH v_signature IN ARRAY ARRAY[
        'axon_register(uuid, boolean)',
        'axon_routes(uuid, boolean)',
        'axon_set_primary_route(uuid, uuid, boolean)',
        'axon_start_waiting(uuid, uuid, uuid, double precision, double precision)',
        'axon_my_waiting(uuid)',
        'axon_driver_map(uuid, uuid)',
        'axon_begin_pickup(uuid, uuid, uuid, boolean, double precision, double precision, timestamptz, double precision, integer)',
        'axon_respond_pickup(uuid, uuid, uuid, boolean)',
        'axon_cancel_waiting(uuid, uuid)',
        'axon_expire_waiting()',
        'axon_admin_routes(uuid)',
        'axon_admin_drivers(uuid)',
        'axon_save_route(uuid, uuid, text, text, boolean)',
        'axon_verify_driver(uuid, uuid, boolean)',
        'axon_assign_driver(uuid, uuid, uuid, boolean)',
        'axon_report_misuse(uuid, uuid, boolean, text, uuid)',
        'axon_moderation_queue(uuid)',
        'axon_review_report(uuid, uuid)',
        'axon_set_restriction(uuid, uuid, boolean, uuid)'
    ] LOOP
        EXECUTE 'REVOKE ALL ON FUNCTION public.' || v_signature || ' FROM PUBLIC, anon, authenticated';
        EXECUTE 'GRANT EXECUTE ON FUNCTION public.' || v_signature || ' TO service_role';
    END LOOP;
END;
$$;

COMMIT;
