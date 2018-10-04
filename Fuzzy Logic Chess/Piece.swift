//
//  Piece.swift
//  Fuzzy Logic Chess
//
//  Created by Illya Balakin on 9/20/18.
//  Copyright © 2018 KSU CS Seniors Project 6A. All rights reserved.
//

class Piece {
	
	var type: PieceType
	var team: Team
	var imageName: String
	var location: Int
	var firstMove: Bool = true	// Pawn only!! -- can move 2 spots if first move..
	
	init(type: PieceType, team: Team, imageName: String, location: Int) {
		self.type = type
		self.team = team
		self.imageName = imageName
		self.location = location
	}
	
	// changes location of piece
	func changeLocation(location: Int) {
		self.location = location
		
		// TODO: if PAWN, firstMove = false
	}
	
	// returns list of legal moves
	func getLegalMoves() -> [Int] {
		var legalMoves = [Int]()
		
		// SURROUNDING THE PIECE...
		// Top, Right, Bottom, Left, Diagonals
		if(location >= 8) {		// TOP
			legalMoves.append(location - 8)
			
			if(location % 8 != 7) {	// TOP-RIGHT
				legalMoves.append(location - 7)
			}
		
			if(location % 8 != 0) {	// TOP-LEFT
				legalMoves.append(location - 9)
			}
		}
		if(location <= 55) {	// BOTTOM
			legalMoves.append(location + 8)
			
			if(location % 8 != 7) {	// BOTTOM-RIGHT
				legalMoves.append(location + 9)
			}
			
			if(location % 8 != 0) {	// BOTTOM-LEFT
				legalMoves.append(location + 7)
			}
		}
		if(location % 8 != 0) {	// LEFT
			legalMoves.append(location - 1)
		}
		if(location % 8 != 7) {	// RIGHT
			legalMoves.append(location + 1)
		}
		
		
		
		
		// PAWN only - first move
		if(firstMove && self.type == PieceType.Pawn) {
			if(self.team == Team.Black) {
				legalMoves.append(location + 16)
			}
			else {
				legalMoves.append(location - 16)
			}
		}
		
		
		
		
	
		// ALL THE WAY TO THE END OF THE BOARD...
		if(self.type == PieceType.Queen) {
			
			var currentTile = location
		
			// Horizontal moves - until edge of board
			// LEFT SIDE
			if(location % 8 != 0) {
				repeat {
					currentTile -= 1
					legalMoves.append(currentTile)
				} while(currentTile % 8 != 0)
			
				currentTile = location	//reset
			}
		
			// RIGHT SIDE
			if(location % 8 != 7) {
				repeat {
					currentTile += 1
					legalMoves.append(currentTile)
				} while(currentTile % 8 != 7)
			
				currentTile = location //reset
			}
			
			// VERTICAL moves - until edge of board
			// TOP
			if(location >= 8) {
				repeat {
					currentTile -= 8
					legalMoves.append(currentTile)
				} while (currentTile >= 8)
			
				currentTile = location	//reset
			}
			
			// BOTTOM
			if(location <= 55) {
				repeat {
					currentTile += 8
					legalMoves.append(currentTile)
				} while(currentTile <= 55)
				
				currentTile = location	//reset
			}
			
			// DIAGONAL moves - until edge of board
			// TOP-LEFT
			if(location >= 8 && location % 8 != 0) {
				repeat {
					currentTile -= 9
					legalMoves.append(currentTile)
				} while (currentTile >= 8 && currentTile % 8 != 0)
				
				currentTile = location	//reset
			}
			
			// TOP-RIGHT
			if(location >= 8 && location % 8 != 7) {
				repeat {
					currentTile -= 7
					legalMoves.append(currentTile)
				} while (currentTile >= 8 && currentTile % 8 != 7)
				
				currentTile = location	//reset
			}
			
			// BOTTOM-LEFT
			if(location <= 55 && location % 8 != 0) {
				repeat {
					currentTile += 7
					legalMoves.append(currentTile)
				} while (currentTile <= 55 && currentTile % 8 != 0)
				
				currentTile = location	//reset
			}
			
			// BOTTOM-RIGHT
			if(location <= 55 && location % 8 != 7) {
				repeat {
					currentTile += 9
					legalMoves.append(currentTile)
				} while (currentTile <= 55 && currentTile % 8 != 7)
				
				currentTile = location	//reset
			}
			
		}
		
		
		
		
		
		// FOR REFERENCE...
		if(location % 8 == 0) {}	// left side of board
		if(location % 8 == 7) {} // right side of board
		
		for i in legalMoves {
			print("legal move: \(i)")
		}
		
		return legalMoves
	}
}


enum PieceType {
	case King
	case Queen
	case Bishop
	case Knight
	case Rook
	case Pawn
}

enum Team {
	case Black
	case White
}
