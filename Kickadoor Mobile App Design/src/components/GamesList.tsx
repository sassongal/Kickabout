import React from 'react';
import { FuturisticCard } from './FuturisticCard';
import { Calendar, Clock, MapPin, Users, Plus } from 'lucide-react';
import { GradientButton } from './GradientButton';
import { mockGames, mockHubs } from '../data/mockData';

interface GamesListProps {
  onGameClick: (gameId: string) => void;
  onCreateGame: () => void;
}

export function GamesList({ onGameClick, onCreateGame }: GamesListProps) {
  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('he-IL', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    }).format(date);
  };

  const formatTime = (date: Date) => {
    return new Intl.DateTimeFormat('he-IL', { 
      hour: '2-digit', 
      minute: '2-digit' 
    }).format(date);
  };

  const getHubName = (hubId: string) => {
    return mockHubs.find(h => h.hubId === hubId)?.name || 'קהילה';
  };

  const getStatusBadge = (status: string) => {
    const statusConfig: { [key: string]: { label: string; color: string } } = {
      'teamSelection': { label: 'גיוס שחקנים', color: 'bg-[#4CAF50]' },
      'inProgress': { label: 'בעיצומו', color: 'bg-[#FF9800]' },
      'completed': { label: 'הסתיים', color: 'bg-[#757575]' },
      'cancelled': { label: 'בוטל', color: 'bg-[#E53935]' }
    };
    return statusConfig[status] || statusConfig['teamSelection'];
  };

  const upcomingGames = mockGames.filter(g => g.status !== 'completed' && g.status !== 'cancelled');
  const pastGames = mockGames.filter(g => g.status === 'completed');

  return (
    <div className="min-h-screen bg-[#F5F5F5] pb-20" dir="rtl">
      {/* App Bar */}
      <div className="bg-white border-b border-[#E0E0E0] px-4 py-4">
        <h2 
          className="text-[#212121] uppercase tracking-wider text-center" 
          style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1.25rem', letterSpacing: '0.1em' }}
        >
          GAMES
        </h2>
      </div>

      <div className="p-4 space-y-6">
        {/* Create Game Button */}
        <GradientButton 
          variant="primary"
          icon={<Plus />}
          onClick={onCreateGame}
          className="w-full"
        >
          צור משחק חדש
        </GradientButton>

        {/* Upcoming Games */}
        <div>
          <h3 
            className="text-[#212121] uppercase tracking-wider mb-4" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
          >
            UPCOMING GAMES
          </h3>
          <div className="space-y-3">
            {upcomingGames.map((game) => {
              const status = getStatusBadge(game.status);
              return (
                <FuturisticCard 
                  key={game.gameId}
                  className="cursor-pointer hover:shadow-lg transition-shadow"
                  onClick={() => onGameClick(game.gameId)}
                >
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h4 className="text-[#212121] mb-1" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700 }}>
                        {getHubName(game.hubId)}
                      </h4>
                      <span className={`${status.color} text-white px-2 py-1 rounded-full`} style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>
                        {status.label}
                      </span>
                    </div>
                    <div className={`${status.color} text-white px-3 py-1 rounded-full`}>
                      <span style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600, fontSize: '0.875rem' }}>
                        {game.signupCount}/{game.maxPlayers}
                      </span>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-4 h-4 text-[#1976D2]" />
                      <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        {formatDate(game.gameDate)}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4 text-[#1976D2]" />
                      <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        {formatTime(game.gameDate)}
                      </span>
                    </div>
                    {game.location && (
                      <div className="flex items-center gap-2">
                        <MapPin className="w-4 h-4 text-[#1976D2]" />
                        <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                          {game.location}
                        </span>
                      </div>
                    )}
                  </div>
                </FuturisticCard>
              );
            })}
          </div>
        </div>

        {/* Past Games */}
        {pastGames.length > 0 && (
          <div>
            <h3 
              className="text-[#212121] uppercase tracking-wider mb-4" 
              style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
            >
              PAST GAMES
            </h3>
            <div className="space-y-3">
              {pastGames.map((game) => (
                <FuturisticCard 
                  key={game.gameId}
                  className="cursor-pointer hover:shadow-lg transition-shadow opacity-75"
                  onClick={() => onGameClick(game.gameId)}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-[#212121] mb-1" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}>
                        {getHubName(game.hubId)}
                      </h4>
                      <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        {formatDate(game.gameDate)} • {formatTime(game.gameDate)}
                      </span>
                    </div>
                    <div className="bg-[#757575] text-white px-2 py-1 rounded-full">
                      <span style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>
                        הסתיים
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
