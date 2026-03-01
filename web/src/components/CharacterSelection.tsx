import React, { useState } from 'react';
import { Character, Locale } from '../types/Character';
import CharacterCard from './CharacterCard';
import CharacterInfo from './CharacterInfo';
import { fetchNui } from '../utils/fetchNui';

interface CharacterSelectionProps {
  initialCharacters: Character[];
  Candelete: boolean;
  MaxAllowedSlot : number;
  locale : Locale;
}

const CharacterSelection: React.FC<CharacterSelectionProps> = ({ initialCharacters, Candelete, MaxAllowedSlot, locale }) => {
  const [characters, setCharacters] = useState<Character[]>(initialCharacters);
  const [showInfo, setShowInfo] = useState<string | null>(null);
  const [selectedCharacter, setSelectedCharacter] = useState<Character | null>(
    characters.find(char => char.isActive) || null
  );

  const handleSelectCharacter = (id: string) => {
    if (selectedCharacter?.id === id) return;

    const updatedCharacters = characters.map(char => ({
      ...char,
      isActive: char.id === id
    }));
    
    setCharacters(updatedCharacters);
    setSelectedCharacter(updatedCharacters.find(char => char.id === id) || null);
    setShowInfo(null);
    fetchNui('SelectCharacter', {id : id})
  };

  const toggleInfo = (id: string) => {
    setShowInfo(showInfo === id ? null : id);
  };

  const PlayCharacter = () => {
    fetchNui('PlayCharacter')
  }

  const handleCreateCharacter = () => {
    fetchNui('CreateCharacter')
  }

  const handleDeleteCharacter = () => {
    if (!selectedCharacter) return;

    const updatedCharactersRaw = characters.filter(char => char.id !== selectedCharacter.id);

    fetchNui('DeleteCharacter');

    if (updatedCharactersRaw.length > 0) {
      const updatedCharacters = updatedCharactersRaw.map((char, index) => ({
        ...char,
        isActive: index === 0
      }));

      setCharacters(updatedCharacters);
      setSelectedCharacter(updatedCharacters[0]);
      setShowInfo(null);
    } else {
      setCharacters([]);
      setSelectedCharacter(null);
      setShowInfo(null);
      handleCreateCharacter();
    }
  };

  return (
    <div className="multicharacter-container">
      <div className="multicharacter-header">
        <h2 className="multicharacter-header-title">{locale.title}</h2>
      </div>
      
      <div className="multicharacter-list">
        {characters.map(character => (
          <div key={character.id}>
            <CharacterCard 
              character={character} 
              onSelect={handleSelectCharacter}
              onInfoClick={toggleInfo}
              showInfo={showInfo === character.id}
              PlayCharacter={PlayCharacter}
            />
            {character.isActive && showInfo === character.id && (
              <CharacterInfo 
                character={character} 
                onClose={() => setShowInfo(null)}
                isAllowedtoDelete={Candelete}
                PlayCharacter={PlayCharacter}
                handleDelete={handleDeleteCharacter}
                locale={locale}
              />
            )}
          </div>
        ))}
      </div>
      
      <div className="multicharacter-footer">
        <button 
          className="create-character-btn"
          onClick={handleCreateCharacter}
          disabled={characters.length >= MaxAllowedSlot}  
        >
          <span className="material-symbols-outlined">add</span>
          <span>Créer un personnage</span>
        </button>
      </div>
    </div>
  );
};

export default CharacterSelection;