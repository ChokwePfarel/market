-- Create buckets for storage
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-images', 'user-images', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS for buckets
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Storage Policies for user-images bucket
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'user-images');

CREATE POLICY "Users can upload their own images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'user-images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can update their own images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'user-images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete their own images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'user-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Create the profiles table
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  full_name TEXT,
  user_type TEXT DEFAULT 'Student',
  has_free_trial BOOLEAN DEFAULT TRUE,
  sex TEXT,
  university TEXT,
  profile_image_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_profile_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 1. Profiles are viewable by any authenticated user
-- (Allows students to see seller information)
CREATE POLICY "Profiles are viewable by authenticated users"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

-- 2. Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 3. Users can update their own profile
CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Function to handle updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update the updated_at column
CREATE TRIGGER on_profile_update
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- Create product_images table
CREATE TABLE public.product_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  url TEXT NOT NULL,
  path TEXT NOT NULL,
  type TEXT NOT NULL, -- 'profile' or 'product'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for product_images
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

-- 1. Anyone authenticated can see images
CREATE POLICY "Images are viewable by authenticated users"
ON public.product_images FOR SELECT
TO authenticated
USING (true);

-- 2. Users can insert their own images
CREATE POLICY "Users can insert their own images"
ON public.product_images FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 3. Users can delete their own images
CREATE POLICY "Users can delete their own images"
ON public.product_images FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Create products table
CREATE TABLE public.products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  category TEXT NOT NULL,
  university TEXT NOT NULL,
  image_urls TEXT[], -- Array of image URLs
  seller_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'active', -- 'active', 'pending_payment', 'sold'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 1. Products are viewable by anyone authenticated
CREATE POLICY "Products are viewable by authenticated users"
ON public.products FOR SELECT
TO authenticated
USING (true);

-- 2. Users can create their own products
CREATE POLICY "Users can create their own products"
ON public.products FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = seller_id);

-- 3. Users can update their own products
CREATE POLICY "Users can update their own products"
ON public.products FOR UPDATE
TO authenticated
USING (auth.uid() = seller_id)
WITH CHECK (auth.uid() = seller_id);

-- 4. Users can delete their own products
CREATE POLICY "Users can delete their own products"
ON public.products FOR DELETE
TO authenticated
USING (auth.uid() = seller_id);

-- Create conversations table
CREATE TABLE public.conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_one_id UUID NOT NULL,
  user_two_id UUID NOT NULL,
  last_message TEXT,
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT conversations_user_one_id_fkey FOREIGN KEY (user_one_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT conversations_user_two_id_fkey FOREIGN KEY (user_two_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  UNIQUE(user_one_id, user_two_id)
);

-- Enable RLS for conversations
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own conversations"
ON public.conversations FOR SELECT TO authenticated
USING (auth.uid() = user_one_id OR auth.uid() = user_two_id);

CREATE POLICY "Users can create their own conversations"
ON public.conversations FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_one_id OR auth.uid() = user_two_id);

CREATE POLICY "Users can update their own conversations"
ON public.conversations FOR UPDATE TO authenticated
USING (auth.uid() = user_one_id OR auth.uid() = user_two_id)
WITH CHECK (auth.uid() = user_one_id OR auth.uid() = user_two_id);

-- Create messages table
CREATE TABLE public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE,
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- Enable RLS for messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 1. Users can see messages in their conversations
CREATE POLICY "Users can view messages in their conversations"
ON public.messages FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.conversations
    WHERE id = conversation_id
    AND (user_one_id = auth.uid() OR user_two_id = auth.uid())
  )
);

-- 2. Users can insert messages in their conversations
CREATE POLICY "Users can send messages to their conversations"
ON public.messages FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1 FROM public.conversations
    WHERE id = conversation_id
    AND (user_one_id = auth.uid() OR user_two_id = auth.uid())
  )
);

-- 3. Users can update messages (e.g. marking as read)
CREATE POLICY "Users can update messages in their conversations"
ON public.messages FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.conversations
    WHERE id = conversation_id
    AND (user_one_id = auth.uid() OR user_two_id = auth.uid())
  )
);

-- Function to update last_message summary in conversation
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations
  SET last_message = NEW.text,
      last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation summary on new message
CREATE TRIGGER on_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_message();

-- RPC Function to get unread count
CREATE OR REPLACE FUNCTION public.get_unread_count(current_user_id UUID)
RETURNS INT AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INT
    FROM public.messages m
    JOIN public.conversations c ON m.conversation_id = c.id
    WHERE (c.user_one_id = current_user_id OR c.user_two_id = current_user_id)
    AND m.sender_id != current_user_id
    AND m.is_read = FALSE
  );
END;
$$ LANGUAGE plpgsql;

-- AUTOMATION: Auto-update has_free_trial to false after first active listing
CREATE OR REPLACE FUNCTION public.consume_free_trial()
RETURNS TRIGGER AS $$
BEGIN
  -- If the new product is active, mark the user's free trial as used
  IF NEW.status = 'active' THEN
    UPDATE public.profiles
    SET has_free_trial = FALSE
    WHERE id = NEW.seller_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_product_listed
AFTER INSERT ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.consume_free_trial();
