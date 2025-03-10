module Paths_rope (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName
  ) where

import Data.Version (Version(..))
import System.Environment (getEnv)

version :: Version
version = Version {versionBranch = [0,5], versionTags = []}

bindir, libdir, datadir, libexecdir :: FilePath

bindir     = "/home/ekmett/.cabal/bin"
libdir     = "/home/ekmett/.cabal/lib/rope-0.5/ghc-6.10.4"
datadir    = "/home/ekmett/.cabal/share/rope-0.5"
libexecdir = "/home/ekmett/.cabal/libexec"

getBinDir, getLibDir, getDataDir, getLibexecDir :: IO FilePath
getBinDir = catch (getEnv "rope_bindir") (\_ -> return bindir)
getLibDir = catch (getEnv "rope_libdir") (\_ -> return libdir)
getDataDir = catch (getEnv "rope_datadir") (\_ -> return datadir)
getLibexecDir = catch (getEnv "rope_libexecdir") (\_ -> return libexecdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
