import React from 'react';
import { StatsRing } from './StatsRing';

interface StatsDashboardProps {
  gamesPlayed: number;
  wins: number;
  goals: number;
  averageRating: number;
}

export function StatsDashboard({ gamesPlayed, wins, goals, averageRating }: StatsDashboardProps) {
  return (
    <div>
      <h2 
        className="text-[#212121] uppercase tracking-widest mb-6" 
        style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1.25rem', letterSpacing: '0.1em' }}
      >
        PERFORMANCE
      </h2>
      <div className="grid grid-cols-2 gap-6">
        <StatsRing 
          value={gamesPlayed} 
          maxValue={100} 
          label="Games Played"
          color="#1976D2"
        />
        <StatsRing 
          value={wins} 
          maxValue={gamesPlayed} 
          label="Wins"
          color="#4CAF50"
        />
        <StatsRing 
          value={goals} 
          maxValue={50} 
          label="Goals"
          color="#9C27B0"
        />
        <StatsRing 
          value={averageRating} 
          maxValue={10} 
          label="Avg Rating"
          color="#FF9800"
        />
      </div>
    </div>
  );
}
