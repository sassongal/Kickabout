import React, { useEffect } from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import { Container, CssBaseline } from '@mui/material';
import Navbar from './components/Navbar';
import Dashboard from './pages/Dashboard';
import GameHistoryPage from './pages/GameHistoryPage';
import { useAppDispatch } from './app/hooks';
import { fetchLatestGame, updateGameFromSocket } from './features/games/gameSlice';
import { fetchPlayers } from './features/players/playersSlice';
import { io } from 'socket.io-client';

const socket = io(import.meta.env.VITE_API_URL || 'http://localhost:5001');

const App: React.FC = () => {
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(fetchLatestGame());
    dispatch(fetchPlayers());

    socket.on('connect', () => {
      console.log('Connected to WebSocket server');
    });

    socket.on('gameUpdate', (game) => {
      console.log('Game update received from server');
      dispatch(updateGameFromSocket(game));
    });
    
    socket.on('playersUpdate', () => {
        console.log('Players update received, refetching players');
        dispatch(fetchPlayers());
    })

    return () => {
      socket.off('connect');
      socket.off('gameUpdate');
      socket.off('playersUpdate');
    };
  }, [dispatch]);

  return (
    <Router>
      <CssBaseline />
      <Navbar />
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/history" element={<GameHistoryPage />} />
        </Routes>
      </Container>
    </Router>
  );
};

export default App;
