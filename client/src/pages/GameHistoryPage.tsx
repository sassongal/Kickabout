import React, { useEffect } from 'react';
import { Container, Typography, Box, CircularProgress } from '@mui/material';
import { useAppDispatch, useAppSelector } from '../app/hooks';
import { fetchPastGames } from '../features/games/gameSlice';
import GameHistoryCard from '../components/GameHistoryCard';

const GameHistoryPage: React.FC = () => {
  const dispatch = useAppDispatch();
  const { pastGames, historyStatus } = useAppSelector((state) => state.game);

  useEffect(() => {
    if (historyStatus === 'idle') {
      dispatch(fetchPastGames());
    }
  }, [historyStatus, dispatch]);

  return (
    <Container maxWidth="md">
      <Typography variant="h4" component="h1" gutterBottom align="center" sx={{ my: 4 }}>
        Game History
      </Typography>
      {historyStatus === 'loading' && (
        <Box sx={{ display: 'flex', justifyContent: 'center' }}>
          <CircularProgress />
        </Box>
      )}
      {historyStatus === 'succeeded' && pastGames.length === 0 && (
        <Typography align="center">No finished games found.</Typography>
      )}
      {historyStatus === 'succeeded' && pastGames.map(game => (
        <GameHistoryCard key={game._id} game={game} />
      ))}
    </Container>
  );
};

export default GameHistoryPage;
