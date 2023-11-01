{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use newtype instead of data" #-}

module SeedPhraseManager 
  ( SeedPhraseParam (..)
  , SeedPhraseDatum (..)
  , requestValidator
  , validatorCode
  ) where

-- import           Data.Maybe                (fromJust)

-- import           Plutus.V1.Ledger.Interval (contains)
-- import           Plutus.V1.Ledger.Address  ( scriptHashAddress, toValidatorHash )
-- import           Plutus.V1.Ledger.Value    (AssetClass, flattenValue)
-- import qualified Plutus.V1.Ledger.Scripts as Scripts

import           Plutus.V2.Ledger.Api      (PubKeyHash, ScriptContext (scriptContextTxInfo), TxInfo (), 
                                            BuiltinByteString, Validator, mkValidatorScript, UnsafeFromData (unsafeFromBuiltinData))
import           Plutus.V2.Ledger.Contexts (txSignedBy)
import           PlutusTx                  (compile, unstableMakeIsData, liftCode, applyCode, makeLift, CompiledCode )
import           PlutusTx.Prelude          hiding (Semigroup (..))
import qualified Prelude                   as Haskell
import           Utilities                 (wrap)

-- Parameter is hash for personal information
-- String for datum should be encrypted with hash for the 23 words + an index of the 24th word --(1 word not encrypted.(USer keeps this for themselves.))
-- PubKeyHash as Datum as well.

data SeedPhraseDatum = SeedPhraseDatum {
    encryptedWordsWithIndex    ::  BuiltinByteString,     
    ownerPKH                   ::  PubKeyHash 
  }
unstableMakeIsData ''SeedPhraseDatum 

data SeedPhraseParam = SeedPhraseParam {
    pInfoHash    :: BuiltinByteString

  } deriving Haskell.Show

unstableMakeIsData ''SeedPhraseParam -- This is to instantiate the IsData class
makeLift ''SeedPhraseParam
    

{-# INLINABLE mkRequestValidator #-}
mkRequestValidator :: SeedPhraseParam -> SeedPhraseDatum -> () -> ScriptContext -> Bool
mkRequestValidator sParam dat () ctx =    
  traceIfFalse "signedByOwner: Not signed by ownerPKH" signedByOwner
  where
    txinfo :: TxInfo
    txinfo = scriptContextTxInfo ctx

    signedByOwner :: Bool
    signedByOwner = txSignedBy txinfo $ ownerPKH dat

---------------------------------------------------------------------------------------------------
------------------------------------ COMPILE VALIDATOR --------------------------------------------

{-# INLINABLE  mkWrappedValidator #-}
mkWrappedValidator :: SeedPhraseParam -> BuiltinData -> BuiltinData -> BuiltinData -> ()
mkWrappedValidator = wrap . mkRequestValidator

requestValidator :: SeedPhraseParam -> Validator
requestValidator cp = mkValidatorScript $
    $$(PlutusTx.compile [|| mkWrappedValidator ||])
    `PlutusTx.applyCode`
    PlutusTx.liftCode cp
    
-- requestValHash :: SeedPhraseParam -> ValidatorHash
-- requestValHash = validatorHash requestValidator

-- address :: SeedPhraseParam -> Address
-- address = scriptHashAddress . requestValHash

{-# INLINABLE  mkWrappedValidatorLucid #-}
--                           PInfoHash    SeedPhraseDatum   redeemer       context
mkWrappedValidatorLucid ::  BuiltinData -> BuiltinData -> BuiltinData -> BuiltinData -> ()
mkWrappedValidatorLucid pIHash = wrap $ mkRequestValidator cp
    where
        cp = SeedPhraseParam
            { pInfoHash = unsafeFromBuiltinData pIHash}

validatorCode :: CompiledCode (BuiltinData -> BuiltinData -> BuiltinData -> BuiltinData -> ())
validatorCode = $$( compile [|| mkWrappedValidatorLucid ||])

-- saveLucidCode :: IO ()
-- saveLucidCode = writeCodeToFile "assets/plutus-scripts/lucid-nft.plutus" nftCode


-- script :: SeedPhraseParam -> Plutus.Script
-- script = Plutus.unValidatorScript . validatorHash

-- scriptAsCbor :: SeedPhraseParam -> LBS.ByteString
-- scriptAsCbor = serialise . validatorHash

-- request :: SeedPhraseParam -> PlutusScript PlutusScriptV1
-- request = PlutusScriptSerialised . requestShortBs

-- requestShortBs :: SeedPhraseParam -> SBS.ShortByteString
-- requestShortBs = SBS.toShort . LBS.toStrict . scriptAsCbor