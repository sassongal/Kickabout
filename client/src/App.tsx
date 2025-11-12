import React, { Suspense, useEffect, useRef } from "react";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import Container from "@mui/material/Container";
import CssBaseline from "@mui/material/CssBaseline";
import Navbar from "./components/Navbar";
import Dashboard from "./pages/Dashboard";
import { useAppDispatch } from "./app/hooks";
import {
  fetchLatestGame,
  updateGameFromSocket,
} from "./features/games/gameSlice";
import { fetchPlayers } from "./features/players/playersSlice";
import type { Socket } from "socket.io-client";

const GameHistoryPage = React.lazy(() => import("./pages/GameHistoryPage"));

const App: React.FC = () => {
  const dispatch = useAppDispatch();
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    let isMounted = true;

    dispatch(fetchLatestGame());
    dispatch(fetchPlayers());

    const bootstrapSocket = async () => {
      const { io } = await import("socket.io-client");
      if (!isMounted) {
        return;
      }

      const socket = io(
        import.meta.env.VITE_API_URL || "http://localhost:5001",
        {
          transports: ["websocket"],
        },
      );
      socketRef.current = socket;

      socket.on("connect", () => {
        console.log("Connected to WebSocket server");
      });

      socket.on("gameUpdate", (game) => {
        console.log("Game update received from server");
        dispatch(updateGameFromSocket(game));
      });

      socket.on("playersUpdate", () => {
        console.log("Players update received, refetching players");
        dispatch(fetchPlayers());
      });
    };

    bootstrapSocket();

    return () => {
      isMounted = false;
      if (socketRef.current) {
        socketRef.current.off("connect");
        socketRef.current.off("gameUpdate");
        socketRef.current.off("playersUpdate");
        socketRef.current.disconnect();
        socketRef.current = null;
      }
    };
  }, [dispatch]);

  return (
    <Router>
      <CssBaseline />
      <Navbar />
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route
            path="/history"
            element={
              <Suspense fallback={<div>טוען היסטוריה...</div>}>
                <GameHistoryPage />
              </Suspense>
            }
          />
        </Routes>
      </Container>
    </Router>
  );
};

export default App;
