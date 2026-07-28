-- ============================================================
-- Clysto Inquiries — schema, indexes, RLS policies, trigger, stats view
-- Safe to re-run: drops any existing objects first, then rebuilds clean.
-- ============================================================

-- Clean slate (handles leftovers from any previous failed run)
DROP VIEW IF EXISTS public.inquiries_stats CASCADE;
DROP TABLE IF EXISTS public.inquiries CASCADE;
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;

-- Create inquiries table
CREATE TABLE public.inquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Inquiry type
  inquiry_type TEXT NOT NULL CHECK (inquiry_type IN ('grow', 'partnership', 'general')),

  -- Common fields (all types)
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,

  -- Optional contact fields
  phone TEXT,
  company_name TEXT,
  website_url TEXT,
  linkedin_url TEXT,

  -- Business information (Grow With Us & Partnerships)
  industry TEXT,
  company_size TEXT,
  monthly_revenue TEXT,

  -- Grow With Us specific
  services TEXT, -- comma-separated
  business_description TEXT,
  project_description TEXT,
  timeline TEXT,
  budget TEXT,

  -- Partnerships specific
  partner_why TEXT,

  -- General inquiry specific
  general_question TEXT,

  -- How they heard about us
  how_heard TEXT,

  -- Metadata
  status TEXT NOT NULL DEFAULT 'New' CHECK (status IN ('New', 'Read', 'Archived')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- For future features
  assigned_to UUID, -- for team member assignment
  notes TEXT,
  tags TEXT -- comma-separated
);

-- Create indexes for performance
CREATE INDEX idx_inquiries_inquiry_type ON public.inquiries(inquiry_type);
CREATE INDEX idx_inquiries_status ON public.inquiries(status);
CREATE INDEX idx_inquiries_created_at ON public.inquiries(created_at DESC);
CREATE INDEX idx_inquiries_email ON public.inquiries(email);
CREATE INDEX idx_inquiries_company_name ON public.inquiries(company_name);

-- Enable Row Level Security
ALTER TABLE public.inquiries ENABLE ROW LEVEL SECURITY;

-- Policy 1: Anyone can INSERT new inquiries (public form submissions)
CREATE POLICY "Allow public to insert inquiries"
  ON public.inquiries
  FOR INSERT
  WITH CHECK (true);

-- Policy 2: Only authenticated admin users can SELECT inquiries
CREATE POLICY "Only authenticated users can read inquiries"
  ON public.inquiries
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Policy 3: Only authenticated admin users can UPDATE inquiries
CREATE POLICY "Only authenticated users can update inquiries"
  ON public.inquiries
  FOR UPDATE
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- Policy 4: Only authenticated admin users can DELETE inquiries
CREATE POLICY "Only authenticated users can delete inquiries"
  ON public.inquiries
  FOR DELETE
  USING (auth.role() = 'authenticated');

-- Create a function to automatically update the updated_at timestamp
CREATE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to call the function
CREATE TRIGGER handle_inquiries_updated_at
  BEFORE UPDATE ON public.inquiries
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Create a view for dashboard stats
CREATE VIEW public.inquiries_stats AS
SELECT
  COUNT(*) as total_inquiries,
  COUNT(*) FILTER (WHERE inquiry_type = 'grow') as grow_inquiries,
  COUNT(*) FILTER (WHERE inquiry_type = 'partnership') as partnership_inquiries,
  COUNT(*) FILTER (WHERE inquiry_type = 'general') as general_inquiries,
  COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE AND status = 'New') as new_today
FROM public.inquiries;

-- Grant access to authenticated users
GRANT SELECT ON public.inquiries_stats TO authenticated;
