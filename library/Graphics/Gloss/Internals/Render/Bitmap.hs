{-# OPTIONS -fwarn-incomplete-patterns #-}

module Graphics.Gloss.Internals.Render.Bitmap
   ( reverseRGBA
   , bitmapPath  )
where

import Foreign
import qualified Data.ByteString as B

-- Generates the point path to display the bitmap centred
bitmapPath :: Float -> Float -> [(Float, Float)]
bitmapPath width height =
   [(-width', -height'), (width', -height'), (width', height'), (-width', height')]
   where
      width'  = width  / 2
      height' = height / 2

-- This is necessary as openGL reads pixel data as ABGR, rather than RGBA
reverseRGBA :: B.ByteString -> IO (Ptr Word8)
reverseRGBA orig =
   do
      ptr  <- newArray $ B.unpack orig
      ptr' <- reverseRGBA' (B.length orig `div` 4) (castPtr ptr) 0
      return $ castPtr ptr'

-- Parses through pixel values, shifting the bytes into OpenGL ABGR order
reverseRGBA' :: Int -> Ptr Word32 -> Int -> IO (Ptr Word32)
reverseRGBA' len ptr count
   | count < len = do
      curr <- peekElemOff ptr count
      let byte0 = shift (isolateByte0 curr) 24
      let byte1 = shift (isolateByte1 curr) 8
      let byte2 = shift (isolateByte2 curr) (-8)
      let byte3 = shift (isolateByte3 curr) (-24)
      pokeElemOff ptr count (byte0 .|. byte1 .|. byte2 .|. byte3)
      reverseRGBA' len ptr (count + 1)
   | otherwise   =
      return ptr

-- These functions work as bit masks to isolate the Word8 components
isolateByte0 :: Word32 -> Word32
isolateByte0 word =
   word .&. (255 :: Word32)
isolateByte1 :: Word32 -> Word32
isolateByte1 word =
   word .&. (65280 :: Word32)
isolateByte2 :: Word32 -> Word32
isolateByte2 word =
   word .&. (16711680 :: Word32)
isolateByte3 :: Word32 -> Word32
isolateByte3 word =
   word .&. (4278190080 :: Word32)
