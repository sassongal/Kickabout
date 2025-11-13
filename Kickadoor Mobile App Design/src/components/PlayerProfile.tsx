import React from 'react';
import { FuturisticCard } from './FuturisticCard';
import { PlayerAvatar } from './PlayerAvatar';
import { ArrowRight, UserPlus, Edit } from 'lucide-react';
import { GradientButton } from './GradientButton';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar } from 'recharts';
import { Progress } from './ui/progress';
import { mockUsers, currentUser } from '../data/mockData';

interface PlayerProfileProps {
  userId: string;
  onBack: () => void;
}

export function PlayerProfile({ userId, onBack }: PlayerProfileProps) {
  const player = mockUsers.find(u => u.uid === userId) || currentUser;
  const isOwnProfile = player.uid === currentUser.uid;

  const getPositionInHebrew = (position: string) => {
    const positions: { [key: string]: string } = {
      'Goalkeeper': 'שוער',
      'Defender': 'מגן',
      'Midfielder': 'קשר',
      'Forward': 'חלוץ'
    };
    return positions[position] || position;
  };

  const ratingHistory = [
    { month: 'Jun', rating: 7.8 },
    { month: 'Jul', rating: 8.0 },
    { month: 'Aug', rating: 7.9 },
    { month: 'Sep', rating: 8.3 },
    { month: 'Oct', rating: 8.5 },
    { month: 'Nov', rating: 8.2 }
  ];

  const radarData = [
    { skill: 'Defense', value: 85 },
    { skill: 'Passing', value: 78 },
    { skill: 'Shooting', value: 72 },
    { skill: 'Dribbling', value: 80 },
    { skill: 'Physical', value: 88 },
    { skill: 'Leadership', value: 75 },
    { skill: 'Team Play', value: 90 },
    { skill: 'Consistency', value: 82 }
  ];

  return (
    <div className="min-h-screen bg-[#F5F5F5] dir-rtl" dir="rtl">
      {/* App Bar */}
      <div className="bg-white border-b border-[#E0E0E0] px-4 py-4 flex items-center justify-between">
        <button onClick={onBack} className="p-2 hover:bg-[#F5F5F5] rounded-full transition-colors">
          <ArrowRight className="w-6 h-6 text-[#757575]" />
        </button>
        <h2 
          className="text-[#212121] uppercase tracking-wider" 
          style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1.25rem', letterSpacing: '0.1em' }}
        >
          PROFILE
        </h2>
        <div className="w-10" />
      </div>

      {/* Content */}
      <div className="p-4 space-y-6">
        {/* Player Info Card */}
        <FuturisticCard>
          <div className="flex flex-col items-center text-center">
            <PlayerAvatar name={player.name} size="xl" status={player.availabilityStatus} />
            <h2 className="mt-4 text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '1.5rem' }}>
              {player.name}
            </h2>
            <p className="text-[#757575] mt-1" style={{ fontFamily: 'Inter, sans-serif' }}>
              {player.email}
            </p>
            <div className="flex items-center gap-4 mt-2 text-[#757575]" style={{ fontFamily: 'Inter, sans-serif' }}>
              {player.city && <span>{player.city}</span>}
              {player.city && <span>•</span>}
              <span>{getPositionInHebrew(player.preferredPosition)}</span>
            </div>
            
            {isOwnProfile ? (
              <GradientButton 
                variant="primary" 
                icon={<Edit />}
                className="mt-4"
              >
                ערוך פרופיל
              </GradientButton>
            ) : (
              <GradientButton 
                variant="primary" 
                icon={<UserPlus />}
                className="mt-4"
              >
                עקוב
              </GradientButton>
            )}

            <div className="flex items-center gap-8 mt-6">
              <div className="text-center">
                <p className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '1.5rem' }}>
                  {Math.floor(Math.random() * 200) + 50}
                </p>
                <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                  עוקבים
                </p>
              </div>
              <div className="text-center">
                <p className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '1.5rem' }}>
                  {Math.floor(Math.random() * 150) + 30}
                </p>
                <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                  עוקב
                </p>
              </div>
            </div>
          </div>
        </FuturisticCard>

        {/* Current Rating */}
        <FuturisticCard>
          <h3 
            className="text-[#212121] uppercase tracking-wider mb-4" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
          >
            CURRENT RATING
          </h3>
          <div className="flex items-end gap-2 mb-3">
            <span className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '3rem', lineHeight: 1 }}>
              {player.currentRankScore.toFixed(1)}
            </span>
            <span className="text-[#757575] pb-2" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600, fontSize: '1.5rem' }}>
              / 10
            </span>
          </div>
          <Progress value={player.currentRankScore * 10} className="h-3" />
          <div className="mt-3 text-center">
            <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
              {player.totalParticipations} משחקים
            </span>
          </div>
        </FuturisticCard>

        {/* Rating History */}
        <FuturisticCard>
          <h3 
            className="text-[#212121] uppercase tracking-wider mb-4" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
          >
            RATING HISTORY
          </h3>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={ratingHistory}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E0E0E0" />
              <XAxis 
                dataKey="month" 
                stroke="#757575"
                style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}
              />
              <YAxis 
                domain={[7, 9]} 
                stroke="#757575"
                style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: '#FFFFFF', 
                  border: '1.5px solid #E0E0E0',
                  borderRadius: '8px',
                  fontFamily: 'Inter, sans-serif'
                }}
              />
              <Line 
                type="monotone" 
                dataKey="rating" 
                stroke="#1976D2" 
                strokeWidth={3}
                dot={{ fill: '#1976D2', r: 5 }}
                activeDot={{ r: 7 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </FuturisticCard>

        {/* Advanced Analytics */}
        <FuturisticCard>
          <h3 
            className="text-[#212121] uppercase tracking-wider mb-4" 
            style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
          >
            ADVANCED ANALYTICS
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <RadarChart data={radarData}>
              <PolarGrid stroke="#E0E0E0" />
              <PolarAngleAxis 
                dataKey="skill" 
                stroke="#757575"
                style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}
              />
              <PolarRadiusAxis 
                angle={90} 
                domain={[0, 100]} 
                stroke="#757575"
                style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}
              />
              <Radar 
                name="Skills" 
                dataKey="value" 
                stroke="#9C27B0" 
                fill="#9C27B0" 
                fillOpacity={0.3}
                strokeWidth={2}
              />
            </RadarChart>
          </ResponsiveContainer>
        </FuturisticCard>
      </div>
    </div>
  );
}
