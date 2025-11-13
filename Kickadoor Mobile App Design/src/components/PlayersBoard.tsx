import React, { useState } from 'react';
import { FuturisticCard } from './FuturisticCard';
import { PlayerAvatar } from './PlayerAvatar';
import { Search, Filter, Star, MapPin } from 'lucide-react';
import { Input } from './ui/input';
import { mockUsers } from '../data/mockData';
import { User } from '../types';

interface PlayersBoardProps {
  onPlayerClick: (userId: string) => void;
}

export function PlayersBoard({ onPlayerClick }: PlayersBoardProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  const filteredPlayers = mockUsers.filter(player =>
    player.name.includes(searchQuery) || player.city?.includes(searchQuery)
  );

  const getPositionInHebrew = (position: string) => {
    const positions: { [key: string]: string } = {
      'Goalkeeper': 'שוער',
      'Defender': 'מגן',
      'Midfielder': 'קשר',
      'Forward': 'חלוץ'
    };
    return positions[position] || position;
  };

  const getStatusColor = (status: string) => {
    const colors: { [key: string]: string } = {
      'available': '#4CAF50',
      'busy': '#FF9800',
      'notAvailable': '#E53935'
    };
    return colors[status] || '#757575';
  };

  return (
    <div className="min-h-screen bg-[#F5F5F5] pb-20" dir="rtl">
      {/* App Bar */}
      <div className="bg-white border-b border-[#E0E0E0] px-4 py-4">
        <h2 
          className="text-[#212121] uppercase tracking-wider text-center mb-4" 
          style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1.25rem', letterSpacing: '0.1em' }}
        >
          PLAYERS BOARD
        </h2>
        
        {/* Search Bar */}
        <div className="relative mb-3">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-[#757575]" />
          <Input
            type="text"
            placeholder="חפש שחקנים..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pr-10 bg-[#E0E0E0] border-[#E0E0E0]"
            style={{ fontFamily: 'Inter, sans-serif' }}
          />
        </div>

        {/* Filter Button */}
        <button
          onClick={() => setShowFilters(!showFilters)}
          className="flex items-center gap-2 px-4 py-2 bg-[#1976D2] text-white rounded-lg w-full justify-center"
          style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}
        >
          <Filter className="w-4 h-4" />
          <span>סינון</span>
        </button>
      </div>

      {/* Players List */}
      <div className="p-4 space-y-3">
        <p className="text-[#757575] mb-2" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
          {filteredPlayers.length} שחקנים נמצאו
        </p>

        {filteredPlayers.map((player) => (
          <FuturisticCard 
            key={player.uid}
            className="cursor-pointer hover:shadow-lg transition-shadow"
            onClick={() => onPlayerClick(player.uid)}
          >
            <div className="flex items-center gap-4">
              <PlayerAvatar 
                name={player.name} 
                status={player.availabilityStatus}
                size="lg"
              />
              
              <div className="flex-1">
                <h3 className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700 }}>
                  {player.name}
                </h3>
                
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                    {getPositionInHebrew(player.preferredPosition)}
                  </span>
                  {player.city && (
                    <>
                      <span className="text-[#E0E0E0]">•</span>
                      <div className="flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-[#757575]" />
                        <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                          {player.city}
                        </span>
                      </div>
                    </>
                  )}
                </div>

                <div className="flex items-center gap-3 mt-2">
                  <div className="flex items-center gap-1">
                    <Star className="w-4 h-4 fill-[#FF9800] text-[#FF9800]" />
                    <span className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}>
                      {player.currentRankScore.toFixed(1)}
                    </span>
                  </div>
                  
                  <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>
                    {player.totalParticipations} משחקים
                  </span>
                </div>
              </div>

              {/* Status Indicator */}
              <div 
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: getStatusColor(player.availabilityStatus) }}
              />
            </div>
          </FuturisticCard>
        ))}
      </div>
    </div>
  );
}
