import React, { useState } from 'react';
import { FuturisticCard } from './FuturisticCard';
import { PlayerAvatar } from './PlayerAvatar';
import { ArrowRight, Users, MapPin, MessageCircle, Calendar, Activity, Plus } from 'lucide-react';
import { GradientButton } from './GradientButton';
import { mockHubs, mockUsers, mockGames, mockFeedPosts } from '../data/mockData';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';

interface HubDetailProps {
  hubId: string;
  onBack: () => void;
  onPlayerClick: (userId: string) => void;
  onGameClick: (gameId: string) => void;
}

export function HubDetail({ hubId, onBack, onPlayerClick, onGameClick }: HubDetailProps) {
  const hub = mockHubs.find(h => h.hubId === hubId);
  const members = mockUsers.filter(u => hub?.memberIds.includes(u.uid));
  const hubGames = mockGames.filter(g => g.hubId === hubId);
  const hubPosts = mockFeedPosts.filter(p => p.hubId === hubId);

  if (!hub) return null;

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
        <button onClick={onBack} className="p-2 hover:bg-[#F5F5F5] rounded-full transition-colors">
          <ArrowRight className="w-6 h-6 text-[#757575]" />
        </button>
        <h2 
          className="text-[#212121] uppercase tracking-wider flex-1 text-center" 
          style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '1rem', letterSpacing: '0.1em' }}
        >
          HUB
        </h2>
        <div className="w-10" />
      </div>

      <div className="p-4 space-y-4">
        {/* Hub Header */}
        <FuturisticCard>
          <div className="text-center">
            <div className="bg-gradient-to-br from-[#1976D2] to-[#9C27B0] w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4">
              <Users className="w-10 h-10 text-white" />
            </div>
            
            <h2 className="text-[#212121] mb-2" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 700, fontSize: '1.5rem' }}>
              {hub.name}
            </h2>
            
            {hub.description && (
              <p className="text-[#757575] mb-4" style={{ fontFamily: 'Inter, sans-serif' }}>
                {hub.description}
              </p>
            )}

            <div className="flex items-center justify-center gap-6 mb-4">
              {hub.city && (
                <div className="flex items-center gap-1">
                  <MapPin className="w-4 h-4 text-[#1976D2]" />
                  <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                    {hub.city}
                  </span>
                </div>
              )}
              <div className="flex items-center gap-1">
                <Users className="w-4 h-4 text-[#4CAF50]" />
                <span className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                  {hub.memberIds.length} חברים
                </span>
              </div>
            </div>

            <GradientButton variant="primary" icon={<Plus />} className="w-full">
              הצטרף לקהילה
            </GradientButton>
          </div>
        </FuturisticCard>

        {/* Tabs */}
        <Tabs defaultValue="overview" className="w-full">
          <TabsList className="grid w-full grid-cols-4 bg-white border border-[#E0E0E0]">
            <TabsTrigger value="overview" style={{ fontFamily: 'Inter, sans-serif' }}>
              סקירה
            </TabsTrigger>
            <TabsTrigger value="games" style={{ fontFamily: 'Inter, sans-serif' }}>
              משחקים
            </TabsTrigger>
            <TabsTrigger value="feed" style={{ fontFamily: 'Inter, sans-serif' }}>
              פיד
            </TabsTrigger>
            <TabsTrigger value="chat" style={{ fontFamily: 'Inter, sans-serif' }}>
              צ'אט
            </TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-4 mt-4">
            {/* Members */}
            <div>
              <h3 
                className="text-[#212121] uppercase tracking-wider mb-3" 
                style={{ fontFamily: 'Orbitron, sans-serif', fontWeight: 700, fontSize: '0.875rem', letterSpacing: '0.1em' }}
              >
                MEMBERS
              </h3>
              <div className="grid grid-cols-2 gap-3">
                {members.map((member) => (
                  <FuturisticCard 
                    key={member.uid}
                    className="cursor-pointer hover:shadow-lg transition-shadow"
                    onClick={() => onPlayerClick(member.uid)}
                  >
                    <div className="flex flex-col items-center text-center">
                      <PlayerAvatar name={member.name} size="md" status={member.availabilityStatus} />
                      <h4 className="mt-2 text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600, fontSize: '0.875rem' }}>
                        {member.name}
                      </h4>
                      <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>
                        {member.currentRankScore.toFixed(1)} ⭐
                      </p>
                    </div>
                  </FuturisticCard>
                ))}
              </div>
            </div>
          </TabsContent>

          <TabsContent value="games" className="space-y-3 mt-4">
            {hubGames.map((game) => (
              <FuturisticCard 
                key={game.gameId}
                className="cursor-pointer hover:shadow-lg transition-shadow"
                onClick={() => onGameClick(game.gameId)}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <Calendar className="w-4 h-4 text-[#1976D2]" />
                      <span className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}>
                        {formatDate(game.gameDate)}
                      </span>
                    </div>
                    {game.location && (
                      <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                        {game.location}
                      </p>
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
          </TabsContent>

          <TabsContent value="feed" className="space-y-3 mt-4">
            {hubPosts.map((post) => (
              <FuturisticCard key={post.postId}>
                <div className="flex items-start gap-3 mb-3">
                  <PlayerAvatar name={post.authorName} size="sm" />
                  <div className="flex-1">
                    <h4 className="text-[#212121]" style={{ fontFamily: 'Montserrat, sans-serif', fontWeight: 600 }}>
                      {post.authorName}
                    </h4>
                    <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.75rem' }}>
                      {formatDate(post.createdAt)}
                    </p>
                  </div>
                </div>
                <p className="text-[#212121] mb-3" style={{ fontFamily: 'Inter, sans-serif' }}>
                  {post.content}
                </p>
                <div className="flex items-center gap-4 text-[#757575]">
                  <button className="flex items-center gap-1">
                    <Activity className="w-4 h-4" />
                    <span style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                      {post.likes.length}
                    </span>
                  </button>
                  <button className="flex items-center gap-1">
                    <MessageCircle className="w-4 h-4" />
                    <span style={{ fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' }}>
                      {post.commentCount}
                    </span>
                  </button>
                </div>
              </FuturisticCard>
            ))}
          </TabsContent>

          <TabsContent value="chat" className="mt-4">
            <FuturisticCard>
              <div className="text-center py-8">
                <MessageCircle className="w-12 h-12 text-[#757575] mx-auto mb-4" />
                <p className="text-[#757575]" style={{ fontFamily: 'Inter, sans-serif' }}>
                  צ'אט הקהילה - בקרוב
                </p>
              </div>
            </FuturisticCard>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
