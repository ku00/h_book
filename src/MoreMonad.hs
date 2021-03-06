import Data.Monoid
import Control.Monad.Writer

-- deprecated
-- import Control.Monad.Instance

import Control.Monad.State
import System.Random
import Data.List

isBigGang :: Int -> (Bool, String)
isBigGang x = (x > 9, "Compared gang size to 9.")

applyLog :: (a, String) -> (a -> (b, String)) -> (b, String)
applyLog (x, log) f = let (y, newLog) = f x in (y, log ++ newLog)

applyLog' :: (Monoid m) => (a, m) -> (a -> (b, m)) -> (b, m)
applyLog' (x, log) f = let (y, newLog) = f x in (y, log `mappend` newLog)

type Food = String
type Price = Sum Int

addDrink :: Food -> (Food, Price)
addDrink "beans" = ("milk", Sum 25)
addDrink "jerky" = ("whiskey", Sum 99)
addDrink _ = ("beer", Sum 30)

logNumber :: Int -> Writer [String] Int
logNumber x = writer (x, ["Got number: " ++ show x])

multWithLog :: Writer [String] Int
multWithLog = do
    a <- logNumber 3
    b <- logNumber 5
    return (a*b)

multWithLog' :: Writer [String] Int
multWithLog' = do
    a <- logNumber 3
    b <- logNumber 5
    tell ["Gonna mutiply these two"]
    return (a*b)

gcd' :: Int -> Int -> Writer [String] Int
gcd' a b
    | b == 0 = do
        tell ["Finished with " ++ show a]
        return a
    | otherwise = do
        tell [show a ++ " mod " ++ show b ++ " = " ++ show (a `mod` b)]
        gcd' b (a `mod` b)

gcdReverse :: Int -> Int -> Writer [String] Int
gcdReverse a b
    | b == 0 = do
        tell ["Finished with " ++ show a]
        return a
    | otherwise = do
        result <- gcdReverse b (a `mod` b)
        tell [show a ++ " mod " ++ show b ++ " = " ++ show (a `mod` b)]
        return result

newtype DiffList a = DiffList { getDiffList :: [a] -> [a] }

toDiffList :: [a] -> DiffList a
toDiffList xs = DiffList (xs++)

fromDiffList :: DiffList a -> [a]
fromDiffList (DiffList f) = f []

instance Monoid (DiffList a) where
    mempty = DiffList (\xs -> [] ++ xs)
    (DiffList f) `mappend` (DiffList g) = DiffList (\xs -> f (g xs))

gcdReverse' :: Int -> Int -> Writer (DiffList String) Int
gcdReverse' a b
    | b == 0 = do
        tell (toDiffList ["Finished with " ++ show a])
        return a
    | otherwise = do
        result <- gcdReverse' b (a `mod` b)
        tell (toDiffList [show a ++ " mod " ++ show b ++ " = " ++ show (a `mod` b)])
        return result

finalCountDown :: Int -> Writer (DiffList String) ()
finalCountDown 0 = do
    tell (toDiffList ["0"])
finalCountDown x = do
    finalCountDown (x-1)
    tell (toDiffList [show x])

finalCountDown' :: Int -> Writer [String] ()
finalCountDown' 0 = do
    tell ["0"]
finalCountDown' x = do
    finalCountDown' (x-1)
    tell [show x]

addStuff :: Int -> Int
addStuff = do
    a <- (*2)
    b <- (+10)
    return (a+b)

type Stack = [Int]

pop :: Stack -> (Int, Stack)
pop (x:xs) = (x, xs)

push :: Int -> Stack -> ((), Stack)
push a xs = ((), a:xs)

stackManip :: Stack -> (Int, Stack)
stackManip stack = let
    ((), newStack1) = push 3 stack
    (a, newStack2) = pop newStack1
    in pop newStack2

pop' :: State Stack Int
pop' = state $ \(x:xs) -> (x, xs)

push' :: Int -> State Stack ()
push' a = state $ \xs -> ((), a:xs)

stackManip' :: State Stack Int
stackManip' = do
    push' 3
    pop'
    pop'

stackStuff :: State Stack ()
stackStuff = do
    a <- pop'
    if a == 5
        then push' 5
        else do
            push' 3
            push' 8

moreStack :: State Stack ()
moreStack = do
    a <- stackManip'
    if a == 100
        then stackStuff
        else return ()

stackyStack :: State Stack ()
stackyStack = do
    stackNow <- get
    if stackNow == [1,2,3]
        then put [8,3,1]
        else put [9,2,1]

pop'' :: State Stack Int
pop'' = do
    (x:xs) <- get
    put xs
    return x

push'' :: Int -> State Stack ()
push'' x = do
    xs <- get
    put (x:xs)

randomSt :: (RandomGen g, Random a) => State g a
randomSt = state random

threeCoins' :: State StdGen (Bool, Bool, Bool)
threeCoins' = do
    a <- randomSt
    b <- randomSt
    c <- randomSt
    return (a, b, c)

solveRPN' :: String -> Maybe Double
solveRPN' st = do
    [result] <- foldM foldingFunction' [] (words st)
    return result

foldingFunction' :: [Double] -> String -> Maybe [Double]
foldingFunction' (x:y:ys) "*" = return ((y * x):ys)
foldingFunction' (x:y:ys) "+" = return ((y + x):ys)
foldingFunction' (x:y:ys) "-" = return ((y - x):ys)
foldingFunction' (x:y:ys) "/" = return ((y / x):ys)
foldingFunction' (x:y:ys) "^" = return ((y ** x):ys)
foldingFunction' (x:xs) "ln"  = return (log x:xs)
foldingFunction' xs "sum"     = return [sum xs]
foldingFunction' xs numberString = liftM (:xs) (readMaybe numberString)

readMaybe :: (Read a) => String -> Maybe a
readMaybe st = case reads st of [(x, "")] -> Just x
                                _ -> Nothing
