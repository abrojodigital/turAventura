-- ─── Extensions ──────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ─── Profiles ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (role IN ('tourist', 'provider', 'admin')),
  full_name   TEXT,
  avatar_url  TEXT,
  phone       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'tourist'),
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── Providers ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.providers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_name   TEXT NOT NULL,
  description     TEXT,
  logo_url        TEXT,
  location        TEXT,
  verified        BOOLEAN NOT NULL DEFAULT FALSE,
  rating          DECIMAL(3,2),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS providers_user_id_idx ON public.providers(user_id);

-- ─── Activities ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.activities (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id      UUID NOT NULL REFERENCES public.providers(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  description      TEXT,
  category         TEXT NOT NULL CHECK (category IN (
    'trekking','rafting','parapente','escalada','kayak',
    'cabalgata','ciclismo','buceo','ski','otro'
  )),
  difficulty       INT NOT NULL CHECK (difficulty BETWEEN 1 AND 5),
  duration_hours   INT,
  price_per_person DECIMAL(10,2) NOT NULL,
  max_participants INT NOT NULL,
  min_age          INT,
  location         TEXT,
  latitude         DECIMAL(10,8),
  longitude        DECIMAL(11,8),
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  search_vector    TSVECTOR,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Full-text search
CREATE OR REPLACE FUNCTION update_activity_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    to_tsvector('spanish', COALESCE(NEW.title, '')) ||
    to_tsvector('spanish', COALESCE(NEW.description, '')) ||
    to_tsvector('simple', COALESCE(NEW.location, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER activities_search_vector_update
  BEFORE INSERT OR UPDATE ON public.activities
  FOR EACH ROW EXECUTE FUNCTION update_activity_search_vector();

CREATE INDEX IF NOT EXISTS activities_search_idx ON public.activities USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS activities_category_idx ON public.activities(category);
CREATE INDEX IF NOT EXISTS activities_provider_idx ON public.activities(provider_id);

-- ─── Activity Images ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.activity_images (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id  UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  url          TEXT NOT NULL,
  is_cover     BOOLEAN NOT NULL DEFAULT FALSE,
  order_index  INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS activity_images_activity_idx ON public.activity_images(activity_id);

-- ─── Availability ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.availability (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id  UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  date         DATE NOT NULL,
  time         TIME,
  total_spots  INT NOT NULL,
  booked_spots INT NOT NULL DEFAULT 0,
  CONSTRAINT booked_le_total CHECK (booked_spots <= total_spots)
);

CREATE INDEX IF NOT EXISTS availability_activity_date_idx ON public.availability(activity_id, date);

-- ─── Bookings ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bookings (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  activity_id      UUID NOT NULL REFERENCES public.activities(id),
  availability_id  UUID NOT NULL REFERENCES public.availability(id),
  participants     INT NOT NULL CHECK (participants > 0),
  total_price      DECIMAL(10,2) NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','cancelled','completed')),
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS bookings_tourist_idx ON public.bookings(tourist_id);
CREATE INDEX IF NOT EXISTS bookings_activity_idx ON public.bookings(activity_id);
CREATE INDEX IF NOT EXISTS bookings_status_idx ON public.bookings(status);

-- ─── Reviews ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reviews (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id      UUID NOT NULL UNIQUE REFERENCES public.bookings(id) ON DELETE CASCADE,
  tourist_id      UUID NOT NULL REFERENCES public.profiles(id),
  activity_id     UUID NOT NULL REFERENCES public.activities(id),
  rating          INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment         TEXT,
  provider_reply  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Update provider rating when review is added
CREATE OR REPLACE FUNCTION update_provider_rating()
RETURNS TRIGGER AS $$
DECLARE
  new_rating DECIMAL(3,2);
  prov_id UUID;
BEGIN
  SELECT p.provider_id INTO prov_id
  FROM public.activities p WHERE p.id = NEW.activity_id;

  SELECT AVG(r.rating) INTO new_rating
  FROM public.reviews r
  JOIN public.activities a ON a.id = r.activity_id
  WHERE a.provider_id = prov_id;

  UPDATE public.providers SET rating = new_rating WHERE id = prov_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reviews_update_provider_rating
  AFTER INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION update_provider_rating();

-- ─── RLS Policies ─────────────────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- profiles: users can read any profile, only update their own
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (TRUE);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- providers: anyone can read, only the owner can write
CREATE POLICY "providers_select" ON public.providers FOR SELECT USING (TRUE);
CREATE POLICY "providers_insert" ON public.providers FOR INSERT WITH CHECK (
  auth.uid() = user_id
);
CREATE POLICY "providers_update" ON public.providers FOR UPDATE USING (
  auth.uid() = user_id
);

-- activities: anyone can read active ones; providers can CRUD their own
CREATE POLICY "activities_select" ON public.activities FOR SELECT USING (
  is_active = TRUE OR provider_id IN (
    SELECT id FROM public.providers WHERE user_id = auth.uid()
  )
);
CREATE POLICY "activities_insert" ON public.activities FOR INSERT WITH CHECK (
  provider_id IN (SELECT id FROM public.providers WHERE user_id = auth.uid())
);
CREATE POLICY "activities_update" ON public.activities FOR UPDATE USING (
  provider_id IN (SELECT id FROM public.providers WHERE user_id = auth.uid())
);
CREATE POLICY "activities_delete" ON public.activities FOR DELETE USING (
  provider_id IN (SELECT id FROM public.providers WHERE user_id = auth.uid())
);

-- activity_images: same as activities
CREATE POLICY "activity_images_select" ON public.activity_images FOR SELECT USING (TRUE);
CREATE POLICY "activity_images_insert" ON public.activity_images FOR INSERT WITH CHECK (
  activity_id IN (
    SELECT id FROM public.activities WHERE provider_id IN (
      SELECT id FROM public.providers WHERE user_id = auth.uid()
    )
  )
);

-- availability: anyone can read; providers can write
CREATE POLICY "availability_select" ON public.availability FOR SELECT USING (TRUE);
CREATE POLICY "availability_insert" ON public.availability FOR INSERT WITH CHECK (
  activity_id IN (
    SELECT id FROM public.activities WHERE provider_id IN (
      SELECT id FROM public.providers WHERE user_id = auth.uid()
    )
  )
);
CREATE POLICY "availability_update" ON public.availability FOR UPDATE USING (
  activity_id IN (
    SELECT id FROM public.activities WHERE provider_id IN (
      SELECT id FROM public.providers WHERE user_id = auth.uid()
    )
  )
);

-- bookings: tourists see their own; providers see bookings for their activities
CREATE POLICY "bookings_tourist_select" ON public.bookings FOR SELECT USING (
  tourist_id = auth.uid() OR
  activity_id IN (
    SELECT id FROM public.activities WHERE provider_id IN (
      SELECT id FROM public.providers WHERE user_id = auth.uid()
    )
  )
);
CREATE POLICY "bookings_insert" ON public.bookings FOR INSERT WITH CHECK (
  tourist_id = auth.uid()
);
CREATE POLICY "bookings_tourist_update" ON public.bookings FOR UPDATE USING (
  tourist_id = auth.uid() OR
  activity_id IN (
    SELECT id FROM public.activities WHERE provider_id IN (
      SELECT id FROM public.providers WHERE user_id = auth.uid()
    )
  )
);

-- reviews: anyone can read; only the tourist of the booking can insert
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT USING (TRUE);
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT WITH CHECK (
  tourist_id = auth.uid() AND
  booking_id IN (
    SELECT id FROM public.bookings WHERE tourist_id = auth.uid() AND status = 'completed'
  )
);
CREATE POLICY "reviews_reply" ON public.reviews FOR UPDATE USING (
  activity_id IN (
    SELECT id FROM public.activities WHERE provider_id IN (
      SELECT id FROM public.providers WHERE user_id = auth.uid()
    )
  )
);

-- ─── Storage ──────────────────────────────────────────────────────────────────
-- Run this in Supabase Storage dashboard or via CLI:
-- supabase storage create activity-images --public
