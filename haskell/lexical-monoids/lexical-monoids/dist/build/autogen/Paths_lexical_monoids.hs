module Paths_lexical_monoids (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName
  ) where

import Data.Version (Version(..))
import System.Environment (getEnv)

version :: Version
version = Version {versionBranch = [0,1,1], versionTags = []}

bindir, libdir, datadir, libexecdir :: FilePath

bindir     = "/home/ekmett/.cabal/bin"
libdir     = "/home/ekmett/.cabal/lib/lexical-monoids-0.1.1/ghc-6.10.1"
datadir    = "/home/ekmett/.cabal/share/lexical-monoids-0.1.1"
libexecdir = "/home/ekmett/.cabal/libexec"

getBinDir, getLibDir, getDataDir, getLibexecDir :: IO FilePath
getBinDir = catch (getEnv "lexical_monoids_bindir") (\_ -> return bindir)
getLibDir = catch (getEnv "lexical_monoids_libdir") (\_ -> return libdir)
getDataDir = catch (getEnv "lexical_monoids_datadir") (\_ -> return datadir)
getLibexecDir = catch (getEnv "lexical_monoids_libexecdir") (\_ -> return libexecdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
