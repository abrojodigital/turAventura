// ─── Enums ────────────────────────────────────────────────────────────────────

export type UserRole = 'tourist' | 'provider' | 'admin'

export type ActivityCategory =
  | 'trekking'
  | 'rafting'
  | 'parapente'
  | 'escalada'
  | 'kayak'
  | 'cabalgata'
  | 'ciclismo'
  | 'buceo'
  | 'ski'
  | 'otro'

export type DifficultyLevel = 1 | 2 | 3 | 4 | 5

export type BookingStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed'

// ─── Database Entities ────────────────────────────────────────────────────────

export interface Profile {
  id: string
  role: UserRole
  full_name: string | null
  avatar_url: string | null
  phone: string | null
  created_at: string
}

export interface Provider {
  id: string
  user_id: string
  business_name: string
  description: string | null
  logo_url: string | null
  location: string | null
  verified: boolean
  rating: number | null
  created_at: string
}

export interface Activity {
  id: string
  provider_id: string
  title: string
  description: string | null
  category: ActivityCategory
  difficulty: DifficultyLevel
  duration_hours: number | null
  price_per_person: number
  max_participants: number
  min_age: number | null
  location: string | null
  latitude: number | null
  longitude: number | null
  is_active: boolean
  created_at: string
}

export interface ActivityImage {
  id: string
  activity_id: string
  url: string
  is_cover: boolean
  order_index: number
}

export interface Availability {
  id: string
  activity_id: string
  date: string
  time: string | null
  total_spots: number
  booked_spots: number
}

export interface Booking {
  id: string
  tourist_id: string
  activity_id: string
  availability_id: string
  participants: number
  total_price: number
  status: BookingStatus
  notes: string | null
  created_at: string
}

export interface Review {
  id: string
  booking_id: string
  tourist_id: string
  activity_id: string
  rating: number
  comment: string | null
  provider_reply: string | null
  created_at: string
}

// ─── Extended / Join Types ────────────────────────────────────────────────────

export interface ActivityWithDetails extends Activity {
  provider: Provider
  images: ActivityImage[]
  avg_rating: number | null
  review_count: number
}

export interface BookingWithDetails extends Booking {
  activity: Activity & { images: ActivityImage[] }
  availability: Availability
  tourist: Profile
}

// ─── Form / Input Types ───────────────────────────────────────────────────────

export interface CreateActivityInput {
  title: string
  description: string
  category: ActivityCategory
  difficulty: DifficultyLevel
  duration_hours: number
  price_per_person: number
  max_participants: number
  min_age: number
  location: string
  latitude?: number
  longitude?: number
}

export interface CreateBookingInput {
  activity_id: string
  availability_id: string
  participants: number
  notes?: string
}

export interface CreateReviewInput {
  booking_id: string
  rating: number
  comment?: string
}

// ─── API Response Types ───────────────────────────────────────────────────────

export interface PaginatedResponse<T> {
  data: T[]
  count: number
  page: number
  pageSize: number
}

export interface ActivityFilters {
  category?: ActivityCategory
  difficulty?: DifficultyLevel
  minPrice?: number
  maxPrice?: number
  location?: string
  search?: string
  sortBy?: 'price_asc' | 'price_desc' | 'rating' | 'created_at'
}
