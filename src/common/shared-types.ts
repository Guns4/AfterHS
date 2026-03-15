export enum UserRole {
  GUEST = "GUEST",
  VENUE_OWNER = "VENUE_OWNER",
  MARKETING = "MARKETING",
  INFLUENCER = "INFLUENCER",
  BRAND_ADMIN = "BRAND_ADMIN",
  PLATFORM_ADMIN = "PLATFORM_ADMIN"
}

export enum VenueCategory {
  CLUB = "CLUB",
  BAR = "BAR",
  KARAOKE = "KARAOKE",
  LIVE_MUSIC = "LIVE_MUSIC",
  SPA_ADULT = "SPA_ADULT"
}

export enum BookingStatus {
  PENDING = "PENDING",
  CONFIRMED = "CONFIRMED",
  CANCELLED = "CANCELLED",
  NO_SHOW = "NO_SHOW",
  CHECKED_IN = "CHECKED_IN"
}

export enum TransactionType {
  TOPUP = "TOPUP",
  GIFT_PURCHASE = "GIFT_PURCHASE",
  BOOKING_DEPOSIT = "BOOKING_DEPOSIT",
  WITHDRAWAL = "WITHDRAWAL"
}

export interface UserProfile {
  id: bigint;
  email?: string | null;
  phone?: string | null;
  displayName: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface VenueProfile {
  id: bigint;
  ownerUserId?: bigint | null;
  name: string;
  category: VenueCategory;
  address?: string | null;
  city?: string | null;
  createdAt: Date;
  updatedAt: Date;
}
