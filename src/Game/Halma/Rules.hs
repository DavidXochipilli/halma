module Game.Halma.Rules
  ( RuleOptions (..)
  , possibleStepMoves
  , possibleJumpMoves
  , possibleMoves
  ) where

import Math.Geometry.Grid
import qualified Math.Geometry.Grid.HexagonalInternal as HI
import Game.Halma.Board
import Data.Default
import Data.Function (on)
import Data.Maybe (catMaybes)
import Control.Monad (guard)
import qualified Data.Set as S

data RuleOptions =
  RuleOptions { backwardsMovesAllowed :: Bool
              } deriving (Show, Eq)

instance Default RuleOptions where
  def = RuleOptions { backwardsMovesAllowed = False }

forwardMovesOnly
  :: RuleOptions
  -> (Int, Int)
  -> HalmaDirection
  -> [(Int, Int)]
  -> [(Int, Int)]
forwardMovesOnly ruleOptions startPos halmaDir =
  if backwardsMovesAllowed ruleOptions
  then id
  else filter (((>=) `on` rowsInDirection halmaDir) startPos)

possibleStepMoves
  :: RuleOptions
  -> HalmaBoard size
  -> (Int, Int)
  -> [(Int, Int)]
possibleStepMoves ruleOptions halmaBoard startPos =
  case lookupHalmaBoard startPos halmaBoard of
    Nothing -> []
    Just team ->
      forwardMovesOnly ruleOptions startPos team $
      filter ((== Nothing) . flip lookupHalmaBoard halmaBoard) $
      neighbours (getGrid halmaBoard) startPos

possibleJumpMoves
  :: RuleOptions
  -> HalmaBoard size
  -> (Int, Int)
  -> [(Int, Int)]
possibleJumpMoves ruleOptions halmaBoard startPos =
  case lookupHalmaBoard startPos halmaBoard of
    Nothing -> []
    Just team ->
      forwardMovesOnly ruleOptions startPos team $
      S.toList $ go S.empty (jumpTargets startPos)
  where hexDirections =
          [ HI.West, HI.Northwest, HI.Northeast
          , HI.East, HI.Southeast, HI.Southwest
          ]
        isEmpty = (== Nothing) . flip lookupHalmaBoard halmaBoard
        maybeJump p dir = do
          next1 <- neighbour (getGrid halmaBoard) p dir
          next2 <- neighbour (getGrid halmaBoard) next1 dir
          guard $ not (isEmpty next1) && isEmpty next2
          return next2
        jumpTargets p = catMaybes $ map (maybeJump p) hexDirections
        go set [] = set
        go set (p:ps) =
          if S.member p set
          then go set ps
          else go (S.insert p set) (jumpTargets p ++ ps)

possibleMoves
  :: RuleOptions
  -> HalmaBoard size
  -> (Int, Int)
  -> [(Int, Int)]
possibleMoves ruleOptions halmaBoard startPos =
  possibleStepMoves ruleOptions halmaBoard startPos ++
  possibleJumpMoves ruleOptions halmaBoard startPos