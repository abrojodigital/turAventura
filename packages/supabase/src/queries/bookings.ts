import { supabase } from '../client'
import type { CreateBookingInput, BookingStatus } from '@turAventura/types'

export async function createBooking(input: CreateBookingInput & { tourist_id: string; total_price: number }) {
  const { data, error } = await supabase
    .from('bookings')
    .insert({
      tourist_id: input.tourist_id,
      activity_id: input.activity_id,
      availability_id: input.availability_id,
      participants: input.participants,
      total_price: input.total_price,
      notes: input.notes ?? null,
      status: 'pending',
    })
    .select()
    .single()

  if (error) throw error

  // Increment booked_spots
  await supabase.rpc('increment_booked_spots', {
    availability_id: input.availability_id,
    count: input.participants,
  })

  return data
}

export async function getTouristBookings(touristId: string) {
  const { data, error } = await supabase
    .from('bookings')
    .select(
      `
      *,
      activity:activities(*, images:activity_images(*)),
      availability:availability(*)
    `
    )
    .eq('tourist_id', touristId)
    .order('created_at', { ascending: false })

  if (error) throw error
  return data ?? []
}

export async function getProviderBookings(providerId: string, status?: BookingStatus) {
  let query = supabase
    .from('bookings')
    .select(
      `
      *,
      activity:activities(title, category),
      availability:availability(date, time),
      tourist:profiles(full_name, avatar_url, phone)
    `
    )
    .eq('activity.provider_id', providerId)
    .order('created_at', { ascending: false })

  if (status) query = query.eq('status', status)

  const { data, error } = await query
  if (error) throw error
  return data ?? []
}

export async function updateBookingStatus(bookingId: string, status: BookingStatus) {
  const { data, error } = await supabase
    .from('bookings')
    .update({ status })
    .eq('id', bookingId)
    .select()
    .single()

  if (error) throw error
  return data
}
