import React, { useState } from 'react';
import { FuturisticCard } from './FuturisticCard';
import { List, Map as MapIcon, Users, MapPin, Activity } from 'lucide-react';
import { mockHubs } from '../data/mockData';

interface HubsBoardProps {
  onHubClick: (hubId: string) => void;
}

export function HubsBoard({ onHubClick }: HubsBoardProps) {
  const [viewMode, setViewMode] = useState<'list' | 'map'>('list');

  return (
    <div className="min-h-screen bg-[#F5F5F5] pb-20" dir="rtl">
      {/* App Bar */}
      <div className="bg-white border-b border-[#E0E0E0] px-4 py-4">
        <div className="flex items-center justify-between mb-4">
          <h2 
            className="text-[#212121] uppercase tracking-wider" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1.25rem', letterSpacing: '0.1em' }}
          >
            HUBS BOARD
          </h2>
          
          {/* View Toggle */}
          <div className="flex gap-2">
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded-lg transition-colors ${
                viewMode === 'list' ? 'bg-[#1976D2] text-white' : 'bg-[#E0E0E0] text-[#757575]'
              }`}
            >
              <List className="w-5 h-5" />
            </button>
            <button
              onClick={() => setViewMode('map')}
              className={`p-2 rounded-lg transition-colors ${
                viewMode === 'map' ? 'bg-[#1976D2] text-white' : 'bg-[#E0E0E0] text-[#757575]'
              }`}
            >
              <MapIcon className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      {viewMode === 'list' ? (
        <div className="p-4 space-y-3">
          <p className="text-[#757575] mb-2" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
            {mockHubs.length} קהילות פעילות
          </p>

          {mockHubs.map((hub) => (
            <FuturisticCard 
              key={hub.hubId}
              className="cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => onHubClick(hub.hubId)}
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <h3 className="text-[#212121] mb-2" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700 }}>
                    {hub.name}
                  </h3>
                  
                  {hub.description && (
                    <p className="text-[#757575] mb-3" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                      {hub.description}
                    </p>
                  )}

                  <div className="flex items-center gap-4 flex-wrap">
                    <div className="flex items-center gap-1">
                      <Users className="w-4 h-4 text-[#1976D2]" />
                      <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        {hub.memberIds.length} חברים
                      </span>
                    </div>

                    {hub.city && (
                      <div className="flex items-center gap-1">
                        <MapPin className="w-4 h-4 text-[#4CAF50]" />
                        <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                          {hub.city}
                        </span>
                      </div>
                    )}

                    <div className="flex items-center gap-1">
                      <Activity className="w-4 h-4 text-[#9C27B0]" />
                      <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        פעילה
                      </span>
                    </div>
                  </div>
                </div>

                {/* Hub Badge */}
                <div className="bg-gradient-to-br from-[#1976D2] to-[#9C27B0] w-12 h-12 rounded-full flex items-center justify-center">
                  <Users className="w-6 h-6 text-white" />
                </div>
              </div>
            </FuturisticCard>
          ))}
        </div>
      ) : (
        <div className="relative h-[calc(100vh-200px)]">
          {/* Map Placeholder */}
          <div className="absolute inset-0 bg-gradient-to-br from-[#E0E0E0] to-[#F5F5F5] flex items-center justify-center">
            <div className="text-center">
              <MapIcon className="w-16 h-16 text-[#757575] mx-auto mb-4" />
              <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif' }}>
                תצוגת מפה - בקרוב
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
