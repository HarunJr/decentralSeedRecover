{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE RankNTypes        #-}

module Utilities.PlutusTx
  ( wrap, wrapPolicy
  ) where

import           Plutus.V2.Ledger.Api (ScriptContext, UnsafeFromData,
                                       unsafeFromBuiltinData)
import           PlutusTx.Prelude     (Bool, BuiltinData, check, ($))

{-# INLINABLE wrap #-}
wrap :: forall a b.
        ( UnsafeFromData a
        , UnsafeFromData b
        )
      => (a -> b -> ScriptContext -> Bool)
      -> (BuiltinData -> BuiltinData -> BuiltinData -> ())
wrap f a b ctx =
  check $ f
      (unsafeFromBuiltinData a)
      (unsafeFromBuiltinData b)
      (unsafeFromBuiltinData ctx)

{-# INLINABLE wrapPolicy #-}
wrapPolicy :: UnsafeFromData a
           => (a -> ScriptContext -> Bool)
           -> (BuiltinData -> BuiltinData -> ())
wrapPolicy f a ctx =
  check $ f
      (unsafeFromBuiltinData a)
      (unsafeFromBuiltinData ctx)