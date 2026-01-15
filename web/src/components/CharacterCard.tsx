import React from 'react';
import { Character } from '../types/Character';

interface CharacterCardProps {
  character: Character;
  onSelect: (id: string) => void;
  onInfoClick: (id: string) => void;
  showInfo: boolean;
  PlayCharacter: () => void;
}

const CharacterCard: React.FC<CharacterCardProps> = ({ 
  character, 
  onSelect, 
  onInfoClick,
  showInfo,
  PlayCharacter
}) => {
  return (
    <div
      className={`character-card ${character.isActive ? 'active' : ''} ${character.disabled ? 'disabled' : ''}`}
      onClick={() => !character.disabled && onSelect(character.id)}
    >
      <div className="character-card-icon">
        <span className="material-symbols-outlined">person</span>
      </div>
      <div className="character-card-name">
        {character.name}
      </div>
      {character.isActive && (
        <div className="character-card-actions">
          {!showInfo && (
            <button 
              className="character-card-btn play"
              onClick={(e) => {
                e.stopPropagation();
                PlayCharacter();
              }}
              disabled={character.disabled}
              title="Jouer"
            >
              <span className="material-symbols-outlined">play_arrow</span>
            </button>
          )}
          <button 
            className="character-card-btn"
            onClick={(e) => {
              e.stopPropagation();
              onInfoClick(character.id);
            }}
            title="Informations"
          >
            <span className="material-symbols-outlined">info</span>
          </button>
        </div>
      )}
    </div>
  )
};

export default CharacterCard;
