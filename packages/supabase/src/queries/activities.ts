import { supabase } from '../client'
import type { ActivityFilters, PaginatedResponse, ActivityWithDetails } from '@turAventura/types'

const PAGE_SIZE = 12

export async function getActivities(
  filters: ActivityFilters = {},
  page = 1
): Promise<PaginatedResponse<ActivityWithDetails>> {
  let query = supabase
    .from('activities')
    .select(
      `
      *,
      provider:providers(*),
      images:activity_images(*),
      reviews(rating)
    `,
      { count: 'exact' }
    )
    .eq('is_active', true)

  if (filters.category) query = query.eq('category', filters.category)
  if (filters.difficulty) query = query.eq('difficulty', filters.difficulty)
  if (filters.minPrice) query = query.gte('price_per_person', filters.minPrice)
  if (filters.maxPrice) query = query.lte('price_per_person', filters.maxPrice)
  if (filters.location) query = query.ilike('location', `%${filters.location}%`)
  if (filters.search) {
    query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
  }

  if (filters.sortBy === 'price_asc') query = query.order('price_per_person', { ascending: true })
  else if (filters.sortBy === 'price_desc') query = query.order('price_per_person', { ascending: false })
  else query = query.order('created_at', { ascending: false })

  const from = (page - 1) * PAGE_SIZE
  query = query.range(from, from + PAGE_SIZE - 1)

  const { data, error, count } = await query

  if (error) throw error

  const activities = (data ?? []).map((a: any) => {
    const reviews = a.reviews ?? []
    const avg_rating = reviews.length > 0
      ? reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / reviews.length
      : null

    return {
      ...a,
      avg_rating,
      review_count: reviews.length,
    } as ActivityWithDetails
  })

  return { data: activities, count: count ?? 0, page, pageSize: PAGE_SIZE }
}

export async function getActivityById(id: string): Promise<ActivityWithDetails | null> {
  const { data, error } = await supabase
    .from('activities')
    .select(
      `
      *,
      provider:providers(*),
      images:activity_images(*),
      reviews(rating, comment, tourist:profiles(full_name, avatar_url), created_at)
    `
    )
    .eq('id', id)
    .single()

  if (error) return null

  const reviews = (data as any).reviews ?? []
  const avg_rating = reviews.length > 0
    ? reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / reviews.length
    : null

  return { ...data, avg_rating, review_count: reviews.length } as ActivityWithDetails
}

export async function getProviderActivities(providerId: string) {
  const { data, error } = await supabase
    .from('activities')
    .select('*, images:activity_images(*)')
    .eq('provider_id', providerId)
    .order('created_at', { ascending: false })

  if (error) throw error
  return data ?? []
}
