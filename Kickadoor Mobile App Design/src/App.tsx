import React, { useState } from 'react';
import { LoginScreen } from './components/LoginScreen';
import { HomeDashboard } from './components/HomeDashboard';
import { PlayerProfile } from './components/PlayerProfile';
import { PlayersBoard } from './components/PlayersBoard';
import { HubsBoard } from './components/HubsBoard';
import { HubDetail } from './components/HubDetail';
import { GamesList } from './components/GamesList';
import { MapView } from './components/MapView';
import { BottomNavigation } from './components/BottomNavigation';

type Screen = 
  | 'login' 
  | 'home' 
  | 'profile' 
  | 'players' 
  | 'hubs' 
  | 'hubDetail'
  | 'games' 
  | 'map';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('login');
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [selectedPlayerId, setSelectedPlayerId] = useState<string>('1');
  const [selectedHubId, setSelectedHubId] = useState<string>('');
  const [selectedGameId, setSelectedGameId] = useState<string>('');

  const handleLogin = () => {
    setIsLoggedIn(true);
    setCurrentScreen('home');
  };

  const handleNavigate = (screen: string) => {
    setCurrentScreen(screen as Screen);
  };

  const handlePlayerClick = (userId: string) => {
    setSelectedPlayerId(userId);
    setCurrentScreen('profile');
  };

  const handleHubClick = (hubId: string) => {
    setSelectedHubId(hubId);
    setCurrentScreen('hubDetail');
  };

  const handleGameClick = (gameId: string) => {
    setSelectedGameId(gameId);
    // In a full app, this would navigate to game detail
  };

  const handleBack = () => {
    setCurrentScreen('home');
  };

  const handleBackToHubs = () => {
    setCurrentScreen('hubs');
  };

  return (
    <div className="max-w-md mx-auto bg-white shadow-2xl min-h-screen relative">
      {!isLoggedIn ? (
        <LoginScreen onLogin={handleLogin} />
      ) : (
        <>
          {currentScreen === 'home' && (
            <HomeDashboard 
              onNavigate={handleNavigate} 
              onPlayerClick={handlePlayerClick}
              onGameClick={handleGameClick}
              onHubClick={handleHubClick}
            />
          )}
          {currentScreen === 'players' && (
            <PlayersBoard onPlayerClick={handlePlayerClick} />
          )}
          {currentScreen === 'hubs' && (
            <HubsBoard onHubClick={handleHubClick} />
          )}
          {currentScreen === 'hubDetail' && (
            <HubDetail 
              hubId={selectedHubId} 
              onBack={handleBackToHubs}
              onPlayerClick={handlePlayerClick}
              onGameClick={handleGameClick}
            />
          )}
          {currentScreen === 'games' && (
            <GamesList 
              onGameClick={handleGameClick}
              onCreateGame={() => {}}
            />
          )}
          {currentScreen === 'map' && (
            <MapView 
              onHubClick={handleHubClick}
              onGameClick={handleGameClick}
            />
          )}
          {currentScreen === 'profile' && (
            <PlayerProfile userId={selectedPlayerId} onBack={handleBack} />
          )}
          
          {currentScreen !== 'profile' && currentScreen !== 'hubDetail' && (
            <BottomNavigation 
              currentScreen={currentScreen} 
              onNavigate={handleNavigate} 
            />
          )}
        </>
      )}
    </div>
  );
}
