module RFB.Security where


import Data.Char (ord)

-- new defined functions used by DES Encryption starts here
----------------

desEncryption :: [Int] -> [[Int]] -> [Int]
desEncryption xs subkeys = desEncryptionIter subkeys left right 0
        where left = firstHalf xip
              right = lastHalf xip
              xip = initPermutation xs

-- l15 = r14
-- r15 = xorTuple (zip l14 (feistel r14 14 subkeys))     
-- r16 = r15
-- l16 = xorTuple (zip l15 (feistel r15 15 subkeys))
desEncryptionIter :: [[Int]] -> [Int] -> [Int] -> Int -> [Int]
desEncryptionIter subkeys left right n
        | n == 16 = (postProcess . finalPermutation) (right ++ left)
        | n < 16  = desEncryptionIter subkeys nl nr (n + 1)
        where nl = right
              nr = xorTuple (zip left (feistel right n subkeys))
              
-- DES functions
------------------------------------------------------------------------
-- initial permutation
initPermutation :: [Int] -> [Int]
initPermutation xs = permutation xs ip

-- final permutation
finalPermutation :: [Int] -> [Int]
finalPermutation xs = permutation xs fp

postProcess :: [Int] -> [Int]
postProcess = map binToDec . splitEvery 8

-- feistel functions
------------------------------------------------------------------------
feistel :: [Int] -> Int -> [[Int]] -> [Int]
feistel rightBlock roundCount subkeys = feistelPermutation (feistelSub (splitEvery 6 (feistelMix rightBlock (subkeys !! roundCount))))

-- feistel key mixing with feistel expansion
feistelMix :: [Int] -> [Int] -> [Int]
feistelMix half subkey = xorTuple (zip (feistelExpansion half) subkey)
-- feistel expansion
feistelExpansion :: [Int] -> [Int]
feistelExpansion xs = permutation xs e
-- feistel substitution
feistelSub :: [[Int]] -> [Int]
feistelSub mixs = concat (localSub mixs 0)
-- feistel permutation
feistelPermutation :: [Int] -> [Int]
feistelPermutation xs = permutation xs p

-- some local functions used in feistel functions
localSub :: [[Int]] -> Int -> [[Int]]
localSub mixs i
               | i == 7 = [lookupSTable (mixs !! i) (subs !! i)]
               | i < 7  = lookupSTable (mixs !! i) (subs !! i) : localSub mixs (i+1)

lookupSTable :: [Int] -> [Int] -> [Int]
lookupSTable block table = (extendListLeft 4 . decToBin) (table !! index)
                        where index = getRow block * 16 + getColumn block
getRow :: [Int] -> Int
getRow bitList
               | h == 0 && l == 0 = 0
               | h == 0 && l == 1 = 1
               | h == 1 && l == 0 = 2
               | h == 1 && l == 1 = 3 
               where h = head bitList
                     l = last bitList   
                                         
getColumn :: [Int] -> Int
getColumn xs = binToDec (init (tail xs))

-- Key management
------------------------------------------------------------------------
-- permuted choice1
permutedChoice1 :: [Int] -> [Int]
permutedChoice1 xs = permutation xs pc1

-- permuted choice2
permutedChoice2 :: [Int] -> [Int]
permutedChoice2 xs = permutation xs pc2

-- convert password text to 64-bit binary (Int list)
-- VNC authentication: Mirror
-- stringToBinaryList str = concatMap charToBitsVNC str
-- General DES
-- stringToBinaryList str = concatMap charToBits str
preProcess :: String -> [Int]
preProcess = extendListRight 64 . concatMap charToBitsVNC

getSubkeysIter :: [[Int]] -> [[Int]] -> [[Int]] -> Int -> [[Int]] 
getSubkeysIter subkeys left right n
        | n == 16 = reverse subkeys
        | n < 16 = getSubkeysIter (nk : subkeys) (nl : left) (nr : right) (n+1)
        where nl = rotateLeft (head left) (ls !! n) 
              nr = rotateLeft (head right) (ls !! n)
              nk = permutedChoice2 (nl ++ nr)
        
-- left1 = rotateLeft left0 (ls !! 0)
-- right1 = rotateLeft right0 (ls !! 0)
-- subkey1 = permutedChoice2 (left1 ++ right1)

getSubkeys :: String -> [[Int]]
getSubkeys mykey = getSubkeysIter [] [left0] [right0] 0
        where left0 = firstHalf pc1
              right0 = lastHalf pc1 
              pc1 = (permutedChoice1 . preProcess) mykey

-- Other functions
------------------------------------------------------------------------

extendListLeft :: Int -> [Int] -> [Int]
extendListLeft n xs
                | a >= n = xs
                | a < n = extendListLeft n (0:xs)
                where a = length xs

extendListRight :: Int -> [Int] -> [Int]
extendListRight n xs = reverse $ extendListLeft n $ reverse xs

-- Permutation: permute xs according to indextable.
permutation :: [Int] -> [Int] -> [Int] -- or [Integral]
permutation xs [] = []
permutation xs (i:indextable)
        | i+1 > length xs = 0 :  permutation xs indextable -- error case
        | otherwise = (xs !! i) : permutation xs indextable

-- Get half list
firstHalf :: [Int] -> [Int]
firstHalf [] = []
firstHalf xs = take (div (length xs) 2) xs

lastHalf :: [Int] -> [Int]
lastHalf [] = []
lastHalf xs = drop (div (length xs) 2) xs

-- split a list into pieces with length n(may not be n for last piece)
splitEvery :: Int -> [Int] -> [[Int]]
splitEvery n xs
                | n >= length xs = [xs]
                | otherwise = take n xs : splitEvery n (drop n xs) 

-- Convert char to binary (8-bit list)
charToBits :: Char -> [Int]
charToBits =  extendListLeft 8 . decToBin . ord
-- 
charToBitsVNC :: Char -> [Int]
charToBitsVNC = reverse . charToBits

-- Convert decimal to 8-bit binary
decToBin8 :: Int -> [Int]
decToBin8 = extendListLeft 8 . decToBin

-- Convert decimal(Int) to binary
decToBin :: Int -> [Int]
decToBin = reverse . localD2B

localD2B :: Int -> [Int]
localD2B 0 = [0]
localD2B 1 = [1]
localD2B n = mod n 2 : localD2B (div n 2)

-- Convert binary to decimal
binToDec :: [Int] -> Int
binToDec = localB2D . reverse
 
localB2D :: [Int] -> Int
localB2D [] = 0
localB2D (x:xs) = x + 2 * localB2D xs

rotateLeft :: [Int] -> Int -> [Int]
rotateLeft bitlist n = drop n bitlist ++ take n bitlist

xorTuple :: [(Int, Int)] -> [Int]
xorTuple [] = []
xorTuple ((a,b):xs) = xorlocal a b : xorTuple xs

xorlocal :: Int -> Int -> Int
xorlocal a b 
        | a == b = 0
        | a /= b = 1

decrease :: Int -> Int
decrease x = x - 1

-- tables
------------------------------------------------------------------------
-- Makes IP(Initial Permutation)
ip0 :: [Int]
ip0 = [58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4,62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8,57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3,61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7]
ip :: [Int]
ip = map decrease ip0

-- Makes IP-1(FP, Final Permutation)
fp0 :: [Int]
fp0 = [40, 8, 48,16,56,24,64,32,39,7, 47,15,55,23,63,31,38,6, 46,14,54,22,62,30,37,5, 45,13,53,21,61,29,36,4, 44,12,52,20,60,28,35,3, 43,11,51,19,59,27,34,2, 42,10,50,18,58,26,33,1, 41,9, 49,17,57,25]
fp :: [Int]
fp = map decrease fp0

-- Make s E (Expansion in Feistel)
e0 :: [Int]
e0 = [32,1, 2, 3, 4, 5,4, 5, 6, 7, 8, 9,8, 9,10,11,12,13,12,13,14,15,16,17,16,17,18,19,20,21,20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1]
e :: [Int]
e = map decrease e0

-- Makes S.
s0,s1,s2,s3,s4,s5,s6,s7 :: [Int]
s0 = [14 :: Int,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7,0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8,4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0,15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13]
s1 = [15 :: Int,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10,3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5,0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15,13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9]
s2 = [10 :: Int,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8,13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1,13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7,1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12]
s3 = [7 :: Int,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15,13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9,10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4,3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14]
s4 = [2 :: Int,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9,14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6,4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14,11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3]
s5 = [12 :: Int,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11,10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8,9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6,4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13]
s6 = [4 :: Int,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1,13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6,1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2,6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12]
s7 = [13 :: Int,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7,1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2,7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8,2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11]
-- substitution table
subs :: [[Int]]
subs = [s0, s1, s2, s3, s4, s5, s6, s7]
 
-- Makes P
p :: [Int]
p = [15,6,19,20,28,11,27,16,0,14,22,25,4,17,30,9,1,7,23,13,31,26,2,8,18,12,29,5,21,10,3,24]

-- Makes PC-1 and -2
-- Permuted choices
pc1 :: [Int]
pc1 = [56,48,40,32,24,16,8,0,57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,60,52,44,36,28,20,12,4,27,19,11,3]
pc2 :: [Int]
pc2 = [13,16,10,23,0,4,2,27,14,5,20,9,22,18,11,3,25,7,15,6,26,19,12,1,40,51,30,36,46,54,29,39,50,44,32,47,43,48,38,55,33,52,45,41,49,35,28,31]

-- Generates left shift table
ls :: [Int]
ls = [1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1]
