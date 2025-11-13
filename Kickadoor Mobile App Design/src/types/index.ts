export interface User {
  uid: string;
  name: string;
  email: string;
  photoUrl?: string;
  phoneNumber?: string;
  city?: string;
  availabilityStatus: 'available' | 'busy' | 'notAvailable';
  createdAt: Date;
  hubIds: string[];
  currentRankScore: number;
  preferredPosition: 'Goalkeeper' | 'Defender' | 'Midfielder' | 'Forward';
  totalParticipations: number;
}

export interface Hub {
  hubId: string;
  name: string;
  description?: string;
  createdBy: string;
  createdAt: Date;
  memberIds: string[];
  location?: {
    lat: number;
    lng: number;
  };
  city?: string;
  radius?: number;
}

export interface Game {
  gameId: string;
  createdBy: string;
  hubId: string;
  gameDate: Date;
  location?: string;
  locationPoint?: {
    lat: number;
    lng: number;
  };
  venueId?: string;
  teamCount: number;
  status: 'teamSelection' | 'inProgress' | 'completed' | 'cancelled';
  photoUrls: string[];
  signupCount: number;
  maxPlayers: number;
}

export interface FeedPost {
  postId: string;
  hubId: string;
  authorId: string;
  authorName: string;
  type: 'text' | 'game' | 'photo';
  content?: string;
  photoUrls: string[];
  gameId?: string;
  createdAt: Date;
  likes: string[];
  commentCount: number;
}
