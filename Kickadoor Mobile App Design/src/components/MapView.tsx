import React from 'react';
import { Map as MapIcon, MapPin, Users } from 'lucide-react';
import { FuturisticCard } from './FuturisticCard';
import { mockHubs, mockGames } from '../data/mockData';

interface MapViewProps {
  onHubClick: (hubId: string) => void;
  onGameClick: (gameId: string) => void;
}

export function MapView({ onHubClick, onGameClick }: MapViewProps) {
  const hubsWithLocation = mockHubs.filter(h => h.location);
  const gamesWithLocation = mockGames.filter(g => g.locationPoint && g.status === 'teamSelection');

  return (
    <div className="min-h-screen bg-[#F5F5F5] pb-20" dir="rtl">
      {/* App Bar */}
      <div className="bg-white border-b border-[#E0E0E0] px-4 py-4">
        <h2 
          className="text-[#212121] uppercase tracking-wider text-center" 
          style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1.25rem', letterSpacing: '0.1em' }}
        >
          MAP
        </h2>
      </div>

      {/* Map Placeholder */}
      <div className="relative h-[400px] bg-gradient-to-br from-[#E0E0E0] to-[#F5F5F5]">
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center">
            <MapIcon className="w-16 h-16 text-[#757575] mx-auto mb-4" />
            <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif' }}>
              מפה אינטראקטיבית - בקרוב
            </p>
          </div>
        </div>

        {/* Mock Pins */}
        <div className="absolute top-1/4 left-1/4">
          <MapPin className="w-8 h-8 text-[#1976D2] fill-[#1976D2]/20" />
        </div>
        <div className="absolute top-1/3 right-1/3">
          <MapPin className="w-8 h-8 text-[#4CAF50] fill-[#4CAF50]/20" />
        </div>
        <div className="absolute bottom-1/3 left-1/2">
          <MapPin className="w-8 h-8 text-[#9C27B0] fill-[#9C27B0]/20" />
        </div>
      </div>

      {/* Nearby Items */}
      <div className="p-4 space-y-4">
        {/* Nearby Hubs */}
        <div>
          <h3 
            className="text-[#212121] uppercase tracking-wider mb-3" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '0.875rem', letterSpacing: '0.1em' }}
          >
            NEARBY HUBS
          </h3>
          <div className="space-y-3">
            {hubsWithLocation.slice(0, 3).map((hub) => (
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
                    <h4 className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700 }}>
                      {hub.name}
                    </h4>
                    <div className="flex items-center gap-2 mt-1">
                      <MapPin className="w-3 h-3 text-[#757575]" />
                      <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        {hub.city} • ~{hub.radius || 5} ק"מ
                      </span>
                    </div>
                  </div>
                </div>
              </FuturisticCard>
            ))}
          </div>
        </div>

        {/* Nearby Games */}
        <div>
          <h3 
            className="text-[#212121] uppercase tracking-wider mb-3" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '0.875rem', letterSpacing: '0.1em' }}
          >
            NEARBY GAMES
          </h3>
          <div className="space-y-3">
            {gamesWithLocation.map((game) => (
              <FuturisticCard 
                key={game.gameId}
                className="cursor-pointer hover:shadow-lg transition-shadow"
                onClick={() => onGameClick(game.gameId)}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="text-[#212121] mb-1" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}>
                      {game.location}
                    </h4>
                    <div className="flex items-center gap-2">
                      <MapPin className="w-3 h-3 text-[#757575]" />
                      <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        ~2 ק"מ
                      </span>
                    </div>
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
      </div>
    </div>
  );
}
