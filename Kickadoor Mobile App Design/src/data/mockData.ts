import { User, Hub, Game, FeedPost } from '../types';

export const mockUsers: User[] = [
  {
    uid: '1',
    name: 'אבי שלום',
    email: 'avi.shalom@example.com',
    city: 'תל אביב',
    availabilityStatus: 'available',
    createdAt: new Date('2024-01-15'),
    hubIds: ['hub1', 'hub2'],
    currentRankScore: 8.2,
    preferredPosition: 'Midfielder',
    totalParticipations: 45
  },
  {
    uid: '2',
    name: 'יוסי כהן',
    email: 'yossi.cohen@example.com',
    city: 'תל אביב',
    availabilityStatus: 'available',
    createdAt: new Date('2024-02-10'),
    hubIds: ['hub1'],
    currentRankScore: 8.7,
    preferredPosition: 'Defender',
    totalParticipations: 38
  },
  {
    uid: '3',
    name: 'דני לוי',
    email: 'dani.levi@example.com',
    city: 'ירושלים',
    availabilityStatus: 'busy',
    createdAt: new Date('2024-03-05'),
    hubIds: ['hub2'],
    currentRankScore: 8.3,
    preferredPosition: 'Midfielder',
    totalParticipations: 52
  },
  {
    uid: '4',
    name: 'רון אברהם',
    email: 'ron.avraham@example.com',
    city: 'חיפה',
    availabilityStatus: 'available',
    createdAt: new Date('2024-01-20'),
    hubIds: ['hub3'],
    currentRankScore: 7.9,
    preferredPosition: 'Forward',
    totalParticipations: 30
  },
  {
    uid: '5',
    name: 'מיכאל דוד',
    email: 'michael.david@example.com',
    city: 'תל אביב',
    availabilityStatus: 'notAvailable',
    createdAt: new Date('2024-04-12'),
    hubIds: ['hub1'],
    currentRankScore: 8.5,
    preferredPosition: 'Goalkeeper',
    totalParticipations: 41
  },
  {
    uid: '6',
    name: 'עומר כץ',
    email: 'omer.katz@example.com',
    city: 'רעננה',
    availabilityStatus: 'available',
    createdAt: new Date('2024-02-28'),
    hubIds: ['hub2'],
    currentRankScore: 7.6,
    preferredPosition: 'Defender',
    totalParticipations: 25
  }
];

export const mockHubs: Hub[] = [
  {
    hubId: 'hub1',
    name: 'קהילת פארק הירקון',
    description: 'משחקים כל שבוע בפארק הירקון, אווירה מצוינת!',
    createdBy: '1',
    createdAt: new Date('2024-01-10'),
    memberIds: ['1', '2', '5'],
    location: { lat: 32.0853, lng: 34.7818 },
    city: 'תל אביב',
    radius: 5
  },
  {
    hubId: 'hub2',
    name: 'כדורגל שכונתי ירושלים',
    description: 'קהילה פעילה של שחקנים בירושלים',
    createdBy: '3',
    createdAt: new Date('2024-02-05'),
    memberIds: ['1', '3', '6'],
    location: { lat: 31.7683, lng: 35.2137 },
    city: 'ירושלים',
    radius: 10
  },
  {
    hubId: 'hub3',
    name: 'המכביה חיפה',
    description: 'משחקים במתקני המכביה כל שישי',
    createdBy: '4',
    createdAt: new Date('2024-01-25'),
    memberIds: ['4'],
    location: { lat: 32.7940, lng: 34.9896 },
    city: 'חיפה',
    radius: 3
  },
  {
    hubId: 'hub4',
    name: 'בית אלפא FC',
    description: 'קהילת כדורגל בדרום תל אביב',
    createdBy: '2',
    createdAt: new Date('2024-03-15'),
    memberIds: ['2', '5'],
    location: { lat: 32.0543, lng: 34.7635 },
    city: 'תל אביב',
    radius: 4
  }
];

export const mockGames: Game[] = [
  {
    gameId: 'game1',
    createdBy: '1',
    hubId: 'hub1',
    gameDate: new Date('2025-11-15T18:00:00'),
    location: 'פארק הירקון - מגרש מרכזי',
    locationPoint: { lat: 32.0853, lng: 34.7818 },
    teamCount: 2,
    status: 'teamSelection',
    photoUrls: [],
    signupCount: 8,
    maxPlayers: 10
  },
  {
    gameId: 'game2',
    createdBy: '3',
    hubId: 'hub2',
    gameDate: new Date('2025-11-18T19:30:00'),
    location: 'פארק סאקר ירושלים',
    locationPoint: { lat: 31.7683, lng: 35.2137 },
    teamCount: 2,
    status: 'teamSelection',
    photoUrls: [],
    signupCount: 6,
    maxPlayers: 10
  },
  {
    gameId: 'game3',
    createdBy: '2',
    hubId: 'hub1',
    gameDate: new Date('2025-11-13T17:00:00'),
    location: 'פארק הירקון - מגרש מרכזי',
    locationPoint: { lat: 32.0853, lng: 34.7818 },
    teamCount: 2,
    status: 'completed',
    photoUrls: [],
    signupCount: 10,
    maxPlayers: 10
  },
  {
    gameId: 'game4',
    createdBy: '4',
    hubId: 'hub3',
    gameDate: new Date('2025-11-20T16:00:00'),
    location: 'מתקני המכביה חיפה',
    locationPoint: { lat: 32.7940, lng: 34.9896 },
    teamCount: 2,
    status: 'teamSelection',
    photoUrls: [],
    signupCount: 4,
    maxPlayers: 12
  }
];

export const mockFeedPosts: FeedPost[] = [
  {
    postId: 'post1',
    hubId: 'hub1',
    authorId: '1',
    authorName: 'אבי שלום',
    type: 'text',
    content: 'מי בא למשחק ביום חמישי? צריכים עוד 2 שחקנים! ⚽',
    photoUrls: [],
    createdAt: new Date('2025-11-12T14:30:00'),
    likes: ['2', '5'],
    commentCount: 3
  },
  {
    postId: 'post2',
    hubId: 'hub1',
    authorId: '2',
    authorName: 'יוסי כהן',
    type: 'game',
    content: 'משחק מעולה אתמול! תודה לכולם 🙌',
    photoUrls: [],
    gameId: 'game3',
    createdAt: new Date('2025-11-11T20:15:00'),
    likes: ['1', '5'],
    commentCount: 5
  },
  {
    postId: 'post3',
    hubId: 'hub2',
    authorId: '3',
    authorName: 'דני לוי',
    type: 'text',
    content: 'חדש בקהילה! מחפש משחקים בסופי שבוע 👋',
    photoUrls: [],
    createdAt: new Date('2025-11-10T09:00:00'),
    likes: ['1'],
    commentCount: 2
  }
];

export const currentUser: User = mockUsers[0];
