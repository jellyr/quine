{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
module Quine.Frustum
  ( Frustum(..)
  , OverlapsFrustum(..)
 -- , buildFrustum
  ) where

import Control.Lens
import Data.Bits
import Data.Bits.Lens
import Data.Data
import Data.Vector -- .Storable
import Data.Word
import GHC.Generics
import Linear
import Prelude hiding (any, all)
import Quine.Bounding.Box
import Quine.Bounding.Sphere
import Quine.GL.Types
import Quine.Plane

data Frustum = Frustum { frustumPlanes :: Vector Plane, frustumPoints :: Vector Vec3 }
  deriving (Show,Eq,Ord,Generic,Typeable,Data)

{-
-- | @buildFrustum origin direction nearZ farZ fovy aspectRatio@
buildFrustum :: Vec3 -> Vec3 -> Vec3 -> Float -> Float -> Float -> Float -> Frustum
buildFrustum origin dir up near far fovy aspect = undefined -- TODO
  where
    t = tan (fovy*0.5)
    nc = origin + near*^dir
    fc = origin + far*^dir
    nh = t * near
    fh = t * far
    nw = nh * aspect
    fw = fh * aspect
-}

instance OverlapsBox Frustum where
  overlapsBox (Frustum ps qs) b@(Box (V3 lx ly lz) (V3 hx hy hz))
    = all (\p -> signedDistance p (pVertex p b) >= 0) ps && foldl' (\r q -> r .|. mask q) (0::Word8) qs == 0x3f
    where mask (V3 x y z) = 0 & partsOf bits .~ [ x >= lx, y >= ly, z >= lz, x <= hx, y <= hy, z <= hz]

class OverlapsFrustum a where
  overlapsFrustum :: a -> Frustum -> Bool

instance OverlapsFrustum Box where
  overlapsFrustum = flip overlapsBox

-- | In theory a sphere _could_ be large enough to pull the same stunt as a box 
instance OverlapsSphere Frustum where
  overlapsSphere (Frustum ps _) (Sphere c r)
    = all (\p -> signedDistance p c + r >= 0) ps

instance OverlapsFrustum Sphere where
  overlapsFrustum = flip overlapsSphere