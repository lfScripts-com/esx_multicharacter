import React from 'react';
import { Character, Locale } from '../types/Character';

interface CharacterInfoProps {
  character: Character;
  onClose: () => void;
  isAllowedtoDelete: boolean;
  PlayCharacter : () => void;
  handleDelete: () => void;
  locale: Locale;
}

const CharacterInfo: React.FC<CharacterInfoProps> = ({ character, onClose, isAllowedtoDelete , PlayCharacter, handleDelete, locale}) => {
  if (!character) return null;

  return (
    <div className="character-info">
      <div className="character-info-header">
        <span className="material-symbols-outlined">info</span>
        <span>{locale.char_info_title}</span>
      </div>
      
      <div className="character-info-grid">
        <div className="character-info-item">
          <span className="material-symbols-outlined character-info-item-icon">cake</span>
          <span className="character-info-item-text">{character.birthDate}</span>
        </div>
        <div className="character-info-item">
          <span className="material-symbols-outlined character-info-item-icon">
            {character.gender === 'MALE' ? 'male' : 'female'}
          </span>
          <span className="character-info-item-text">{character.gender}</span>
        </div>
        <div className="character-info-item full">
          <span className="material-symbols-outlined character-info-item-icon">work</span>
          <span className="character-info-item-text">{character.occupation}</span>
        </div>
      </div>

      <div className="character-info-actions">
        <button
          className={`character-info-btn play ${character.disabled ? 'disabled' : ''}`}
          onClick={PlayCharacter}
          disabled={character.disabled}
        >
          <span className="material-symbols-outlined">play_arrow</span>
          <span>{locale.play}</span>
        </button>
        {isAllowedtoDelete && (
          <button
            className="character-info-btn delete"
            onClick={handleDelete}
            title="Supprimer"
          >
            <span className="material-symbols-outlined">delete</span>
          </button>
        )}
      </div>
    </div>
  );
};

export default CharacterInfo;