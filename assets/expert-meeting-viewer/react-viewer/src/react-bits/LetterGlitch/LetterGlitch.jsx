import { useEffect, useMemo, useState } from 'react';
import './LetterGlitch.css';

const glyphs = 'AGENCYMEETING0110<>[]{}#/\\|+-';

function makeCells(seedText, count) {
  const base = seedText || 'AGENCY';

  return Array.from({ length: count }, (_, index) => {
    const source = index % 5 === 0 ? base[index % base.length] : glyphs[(index * 7 + base.length) % glyphs.length];
    return {
      id: index,
      char: source,
      tone: index % 7
    };
  });
}

export default function LetterGlitch({ className = '', text = 'AGENCY', cellCount = 180, active = true }) {
  const initialCells = useMemo(() => makeCells(text, cellCount), [text, cellCount]);
  const [cells, setCells] = useState(initialCells);

  useEffect(() => {
    setCells(initialCells);
  }, [initialCells]);

  useEffect(() => {
    if (!active) {
      return undefined;
    }

    const timer = window.setInterval(() => {
      setCells((current) =>
        current.map((cell, index) => {
          if ((index + Date.now()) % 6 > 1) {
            return cell;
          }

          return {
            ...cell,
            char: glyphs[(index + Math.floor(Math.random() * glyphs.length)) % glyphs.length],
            tone: Math.floor(Math.random() * 7)
          };
        })
      );
    }, 180);

    return () => window.clearInterval(timer);
  }, [active]);

  return (
    <div className={`letter-glitch ${className}`} data-active={active ? 'true' : 'false'} aria-hidden="true">
      {cells.map((cell) => (
        <span key={cell.id} data-tone={cell.tone}>
          {cell.char}
        </span>
      ))}
    </div>
  );
}
