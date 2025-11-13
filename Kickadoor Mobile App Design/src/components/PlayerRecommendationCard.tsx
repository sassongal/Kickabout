import React from "react";
import { FuturisticCard } from "./FuturisticCard";
import { PlayerAvatar } from "./PlayerAvatar";
import { Star } from "lucide-react";

interface PlayerRecommendationCardProps {
  name: string;
  position: string;
  city: string;
  rating: number;
  status?: "available" | "busy" | "unavailable";
  imageUrl?: string;
}

export function PlayerRecommendationCard({
  name,
  position,
  city,
  rating,
  status,
  imageUrl,
}: PlayerRecommendationCardProps) {
  return (
    <FuturisticCard
      glow
      className="flex items-center gap-4 cursor-pointer hover:shadow-xl transition-shadow"
    >
      <PlayerAvatar
        name={name}
        imageUrl={imageUrl}
        status={status}
        size="lg"
      />
      <div className="flex-1">
        <h3
          className="text-[#212121]"
          style={{
            fontFamily: "Montserrat, sans-serif",
            fontWeight: 700,
          }}
        >
          {name}
        </h3>
        <p
          className="text-[#757575]"
          style={{ fontFamily: "Inter, sans-serif" }}
        >
          {position} • {city}
        </p>
        <div className="flex items-center gap-1 mt-1">
          <Star className="w-4 h-4 fill-[#FF9800] text-[#FF9800]" />
          <span
            className="text-[#212121]"
            style={{
              fontFamily: "Montserrat, sans-serif",
              fontWeight: 600,
            }}
          >
            {rating.toFixed(1)}
          </span>
        </div>
      </div>
    </FuturisticCard>
  );
}