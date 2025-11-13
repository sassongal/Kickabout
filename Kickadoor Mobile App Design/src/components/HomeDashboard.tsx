import React from 'react';
import { FuturisticCard } from './FuturisticCard';
import { StatsDashboard } from './StatsDashboard';
import { PlayerRecommendationCard } from './PlayerRecommendationCard';
import { Bell, Calendar, MapPin, Clock, Users, Plus, TrendingUp } from 'lucide-react';
import { PlayerAvatar } from './PlayerAvatar';
import { GradientButton } from './GradientButton';
import { Switch } from './ui/switch';
import { Label } from './ui/label';
import { currentUser, mockGames, mockHubs, mockUsers } from '../data/mockData';

interface HomeDashboardProps {
  onNavigate: (screen: string) => void;
  onPlayerClick: (userId: string) => void;
  onGameClick: (gameId: string) => void;
  onHubClick: (hubId: string) => void;
}

export function HomeDashboard({ onNavigate, onPlayerClick, onGameClick, onHubClick }: HomeDashboardProps) {
  const upcomingGames = mockGames.filter(g => g.status === 'teamSelection').slice(0, 2);
  const userHubs = mockHubs.filter(h => currentUser.hubIds.includes(h.hubId));
  const recommendedPlayers = mockUsers.filter(u => u.uid !== currentUser.uid && u.availabilityStatus === 'available').slice(0, 2);

  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('he-IL', { 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  };

  return (
    <div className="min-h-screen bg-[#F5F5F5] pb-20" dir="rtl">
      {/* App Bar */}
      <div className="bg-white border-b border-[#E0E0E0] px-4 py-4 flex items-center justify-between">
        <h2 
          className="text-[#212121] uppercase tracking-wider" 
          style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1.25rem', letterSpacing: '0.1em' }}
        >
          DASHBOARD
        </h2>
        <div className="flex items-center gap-3">
          <button className="p-2 hover:bg-[#F5F5F5] rounded-full transition-colors">
            <Bell className="w-6 h-6 text-[#757575]" />
          </button>
          <button onClick={() => onPlayerClick(currentUser.uid)} className="p-1">
            <PlayerAvatar name={currentUser.name} size="sm" status={currentUser.availabilityStatus} />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="p-4 space-y-6">
        {/* User Profile Card */}
        <FuturisticCard>
          <div className="flex items-center gap-4 mb-4">
            <PlayerAvatar name={currentUser.name} size="lg" status={currentUser.availabilityStatus} />
            <div className="flex-1">
              <h3 className="text-[#212121] mb-1" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '1.25rem' }}>
                {currentUser.name}
              </h3>
              <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                {currentUser.city}
              </p>
            </div>
            <div className="text-center">
              <div className="text-[#1976D2]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '2rem', lineHeight: 1 }}>
                {currentUser.currentRankScore.toFixed(1)}
              </div>
              <div className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>
                דירוג
              </div>
            </div>
          </div>
          
          <div className="flex items-center justify-between pt-3 border-t border-[#E0E0E0]">
            <Label htmlFor="availability" className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif' }}>
              זמין למשחקים
            </Label>
            <Switch id="availability" defaultChecked={currentUser.availabilityStatus === 'available'} />
          </div>
        </FuturisticCard>

        {/* Quick Actions */}
        <div className="grid grid-cols-3 gap-3">
          <button 
            onClick={() => onNavigate('games')}
            className="bg-gradient-to-br from-[#1976D2] to-[#1565C0] text-white p-4 rounded-lg flex flex-col items-center gap-2"
          >
            <Plus className="w-6 h-6" />
            <span style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>צור משחק</span>
          </button>
          <button 
            onClick={() => onNavigate('players')}
            className="bg-gradient-to-br from-[#4CAF50] to-[#388E3C] text-white p-4 rounded-lg flex flex-col items-center gap-2"
          >
            <Users className="w-6 h-6" />
            <span style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>מצא שחקנים</span>
          </button>
          <button 
            onClick={() => onNavigate('hubs')}
            className="bg-gradient-to-br from-[#9C27B0] to-[#7B1FA2] text-white p-4 rounded-lg flex flex-col items-center gap-2"
          >
            <TrendingUp className="w-6 h-6" />
            <span style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>גלה קהילות</span>
          </button>
        </div>

        {/* Stats Dashboard */}
        <FuturisticCard>
          <StatsDashboard 
            gamesPlayed={currentUser.totalParticipations}
            wins={28}
            goals={12}
            averageRating={currentUser.currentRankScore}
          />
        </FuturisticCard>

        {/* My Hubs */}
        {userHubs.length > 0 && (
          <div>
            <h2 
              className="text-[#212121] uppercase tracking-widest mb-4" 
              style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
            >
              MY HUBS
            </h2>
            <div className="space-y-3">
              {userHubs.map((hub) => (
                <FuturisticCard 
                  key={hub.hubId}
                  className="cursor-pointer hover:shadow-lg transition-shadow"
                  onClick={() => onHubClick(hub.hubId)}
                >
                  <div className="flex items-center gap-3">
                    <div className="bg-gradient-to-br from-[#1976D2] to-[#9C27B0] w-12 h-12 rounded-full flex items-center justify-center">
                      <Users className="w-6 h-6 text-white" />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700 }}>
                        {hub.name}
                      </h3>
                      <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        {hub.memberIds.length} חברים
                      </p>
                    </div>
                  </div>
                </FuturisticCard>
              ))}
            </div>
          </div>
        )}

        {/* AI Recommendations */}
        <div>
          <h2 
            className="text-[#212121] uppercase tracking-widest mb-4" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
          >
            AI RECOMMENDATIONS
          </h2>
          <div className="space-y-3">
            {recommendedPlayers.map((player) => (
              <div key={player.uid} onClick={() => onPlayerClick(player.uid)}>
                <PlayerRecommendationCard
                  name={player.name}
                  position={player.preferredPosition === 'Midfielder' ? 'קשר' : player.preferredPosition === 'Defender' ? 'מגן' : player.preferredPosition}
                  city={player.city || ''}
                  rating={player.currentRankScore}
                  status={player.availabilityStatus}
                />
              </div>
            ))}
          </div>
        </div>

        {/* Upcoming Games */}
        {upcomingGames.length > 0 && (
          <div>
            <h2 
              className="text-[#212121] uppercase tracking-widest mb-4" 
              style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
            >
              UPCOMING GAMES
            </h2>
            <div className="space-y-3">
              {upcomingGames.map((game) => (
                <FuturisticCard 
                  key={game.gameId}
                  className="cursor-pointer hover:shadow-lg transition-shadow"
                  onClick={() => onGameClick(game.gameId)}
                >
                  <div className="flex items-start justify-between">
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <Calendar className="w-4 h-4 text-[#1976D2]" />
                        <span className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}>
                          {formatDate(game.gameDate)}
                        </span>
                      </div>
                      {game.location && (
                        <div className="flex items-center gap-2">
                          <MapPin className="w-4 h-4 text-[#1976D2]" />
                          <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif' }}>
                            {game.location}
                          </span>
                        </div>
                      )}
                    </div>
                    <div className="bg-[#4CAF50] text-white px-3 py-1 rounded-full">
                      <span style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600, fontSize: '0.875rem' }}>
                        {game.signupCount}/{game.maxPlayers}
                      </span>
                    </div>
                  </div>
                </FuturisticCard>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
