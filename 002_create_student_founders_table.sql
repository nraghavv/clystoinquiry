-- ============================================================
-- Clysto — Student Founders Program applications
-- Safe to re-run: drops any existing objects first, then rebuilds clean.
-- ============================================================

DROP TABLE IF EXISTS public.student_founders_applications CASCADE;
DROP FUNCTION IF EXISTS public.handle_sfa_updated_at() CASCADE;

CREATE TABLE public.student_founders_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  status TEXT NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending','Shortlisted','Interview','Accepted','Rejected','Archived')),

  -- Step 1: Personal Information
  name TEXT NOT NULL,
  age TEXT,
  institution TEXT NOT NULL,
  grade_year TEXT,
  course TEXT,

  -- Step 2: About You
  about TEXT,

  -- Step 3: Your Startup
  startup_name TEXT,
  startup_stage TEXT CHECK (startup_stage IS NULL OR startup_stage IN ('Idea','Prototype','MVP','Early Users','Revenue')),
  idea TEXT,

  -- Step 4: Help Required (comma-separated)
  help_needed TEXT,

  -- Step 5: Product Links
  website TEXT,
  app_link TEXT,
  github TEXT,
  figma TEXT,
  demo_video TEXT,
  linkedin TEXT,

  -- Step 6: Why Select Me
  why_select TEXT,

  -- Admin-only fields
  notes TEXT,
  reviewed_by TEXT
);

-- Indexes for common queries
CREATE INDEX idx_sfa_status ON public.student_founders_applications(status);
CREATE INDEX idx_sfa_created_at ON public.student_founders_applications(created_at DESC);
CREATE INDEX idx_sfa_institution ON public.student_founders_applications(institution);

-- Row Level Security
ALTER TABLE public.student_founders_applications ENABLE ROW LEVEL SECURITY;

-- Anyone can submit an application
CREATE POLICY "Allow public to insert applications"
  ON public.student_founders_applications
  FOR INSERT
  WITH CHECK (true);

-- Only authenticated admins can read/update/delete
CREATE POLICY "Only authenticated users can read applications"
  ON public.student_founders_applications
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Only authenticated users can update applications"
  ON public.student_founders_applications
  FOR UPDATE
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Only authenticated users can delete applications"
  ON public.student_founders_applications
  FOR DELETE
  USING (auth.role() = 'authenticated');

-- Keep last_updated current on every edit
CREATE FUNCTION public.handle_sfa_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_sfa_last_updated
  BEFORE UPDATE ON public.student_founders_applications
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_sfa_updated_at();

-- Stats view for the admin dashboard
CREATE OR REPLACE VIEW public.sfa_stats AS
SELECT
  COUNT(*) AS total_applications,
  COUNT(*) FILTER (WHERE status = 'Pending') AS pending_count,
  COUNT(*) FILTER (WHERE status = 'Accepted') AS accepted_count,
  COUNT(*) FILTER (WHERE status = 'Rejected') AS rejected_count,
  COUNT(*) FILTER (WHERE status = 'Interview') AS interview_count,
  COUNT(*) FILTER (WHERE created_at >= date_trunc('week', NOW())) AS this_week_count
FROM public.student_founders_applications;

GRANT SELECT ON public.sfa_stats TO authenticated;
