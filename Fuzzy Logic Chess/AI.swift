//
//  AI.swift
//  Fuzzy Logic Chess
//
//  Created by Brian Iruka on 10/22/18.
//  Copyright © 2018 KSU CS Seniors Project 6A. All rights reserved.
//
import GameplayKit

 var AIKing: Piece!//AIs king
	//get empty spots around King (can me modified for Queen as well)
	func getKingsVulnerableCells(board:Board)->[Int]{
		var emptySquaresNearKing = [Int]()
		for cell in AIKing.getSurroundingCells(board: board) {
			if (board.getPieceAtLocation(location: cell) == nil){
				emptySquaresNearKing.append(cell)
			}
		}
		return emptySquaresNearKing
	}

func kingRetreatMove(board:Board)->AIMove?{//returns a move for the king to move backwards, nil if no retreat move available
	var retreatMove: AIMove?
	let kingRow: Int = AIKing.location/8
	for r in getKingsVulnerableCells(board: board){
		let emptyCellBehind: Int = r/8
		if (kingRow - emptyCellBehind == 1 && AIKing.getCanMove()){
			retreatMove = AIMove(pieceToMove: AIKing, attackedPiece: nil, oldPos: AIKing.location, newPos: r, isAttackMove: false, moveBenefit: 0.0)
			return retreatMove
		}
	}
	return nil
}
//returns array of AI Moves containing opponents pieces that can reach AI King within their next two moves
//only called when there are vulnerable cells near king
func getKingThreats(board:Board)->[AIMove]{
	var threatMoves: [AIMove] = []
	for wp in board.whitePieces {
		let oldPieceLocation = wp.location
		let emptyKingSquares: [Int] = getKingsVulnerableCells(board: board)
		for um in wp.getUnfilteredMoves(board: board){
			if (board.getPieceAtLocation(location: um) == nil) {
				if (emptyKingSquares.contains(um)){
					let attackProb = Double(7 - wp.getMinRollNeeded(pieceToAttack: AIKing.type))/6
					threatMoves.append(AIMove(pieceToMove: wp, attackedPiece: AIKing, oldPos: oldPieceLocation, newPos: um, isAttackMove: false, moveBenefit:attackProb))
				}
				wp.changeLocation(location: um)
				for um2 in wp.getSurroundingCells(board: board){//upcast to piece class,
					if (board.getPieceAtLocation(location: um2) == nil) {
					//print("if \(wp.type) at \(oldPieceLocation) moved to \(um), a next possible move could be \(um2)")
						if (emptyKingSquares.contains(um2)){
							//print("King attack eminent")
							let attackProb = Double(7 - wp.getMinRollNeeded(pieceToAttack: AIKing.type))/6
							threatMoves.append(AIMove(pieceToMove: wp, attackedPiece: AIKing, oldPos: oldPieceLocation, newPos: um2, isAttackMove: false, moveBenefit:attackProb))
						}
						
					}
				}
			}

		}
		wp.changeLocation(location: oldPieceLocation)
	}

	return threatMoves
}
//**gets empty squares around king
//sees which white pieces have legal moves to empty square within first or second move
//returns all threat moves


//when a piece is in striking distance but not directly next to AIKing
func defendKing(board:Board, threatMoves:[AIMove],turnCounter:Int)->AIMove{
	let start = NSDate()
	var defenseMove: AIMove?
	var greatestThreatMove: AIMove = threatMoves.first!
	for t in threatMoves{//finds and returns the aimove with the greatest movebenefit (in this case attack prob)
		if (t.moveBenefit > greatestThreatMove.moveBenefit){
			greatestThreatMove = t
		}
	}
	
	for bp in board.blackPieces {//first check to see if moving any pieces will get king out of harm
		let oldPieceLocation = bp.location
		var bestKingProtectMove: AIMove?
		var neutralizedThreatsVal: Int = 0
		for um in getLegalMovesForPiece(board: board, thisPiece: bp){
				bp.changeLocation(location: um)
			let currentKingThreatsVal = getKingThreats(board: board).count
			if (currentKingThreatsVal == 0){
				bp.changeLocation(location: oldPieceLocation)
				
				return AIMove(pieceToMove: bp, attackedPiece: nil, oldPos: oldPieceLocation, newPos: um, isAttackMove: false, moveBenefit: 0.0)
			} else if (currentKingThreatsVal < threatMoves.count){
				let currentBestMove = AIMove(pieceToMove: bp, attackedPiece: nil, oldPos: oldPieceLocation, newPos: um, isAttackMove: false, moveBenefit: 0.0)
				bestKingProtectMove = (currentKingThreatsVal > neutralizedThreatsVal) ? currentBestMove: bestKingProtectMove
				neutralizedThreatsVal = (currentKingThreatsVal > neutralizedThreatsVal) ? currentKingThreatsVal: neutralizedThreatsVal
			}
			
		bp.changeLocation(location: oldPieceLocation)
			}
		if (bestKingProtectMove != nil){
			return bestKingProtectMove!
		}
	}

		var AIHeroPieces: [Piece] = [] //pieces that can immediately attack gtm piece
		for bp in board.blackPieces {

			if (getPiecesDistance(firstPiece: bp, secondPiece: greatestThreatMove.pieceToMove) == 1 && bp.getCanAttack()){
				//piece has to be able to attack
				AIHeroPieces.append(bp)
			}
		}

				var allMovesToTarget: [AIMove] = []
				for hp in AIHeroPieces{// legal moves of all pieces that reach greatest threat piece

					let attackProb = Double(7 - hp.getMinRollNeeded(pieceToAttack: greatestThreatMove.pieceToMove.type))/6.0
					let	moveBenefit = 1.5 * Double(greatestThreatMove.pieceToMove.pieceValue) * attackProb  //gives small benefit to attacking when possible
					allMovesToTarget.append(AIMove(pieceToMove: hp, attackedPiece: greatestThreatMove.pieceToMove, oldPos: hp.location, newPos: greatestThreatMove.pieceToMove.location, isAttackMove: true, moveBenefit:moveBenefit))
				}

	if(AIHeroPieces.count == 0){//gets empty cells surrounding threat piece (if no hero piece)
		var cellsSurroundingTarget = greatestThreatMove.pieceToMove.getSurroundingCells(board: board)
		var i: Int = 0
		var j: Int = 0 //adjust index based on how many objects have been removed
		for c in cellsSurroundingTarget{
			if (board.getPieceAtLocation(location: c) != nil){
				cellsSurroundingTarget.remove(at: i-j)
				j += 1
			}
			i += 1
		}

		for b in board.blackPieces{
			let bLegalMoves = getLegalMovesForPiece(board: board, thisPiece: b)
			for move in bLegalMoves{
				if (cellsSurroundingTarget.contains(move)){
					let attackProb = Double(7 - b.getMinRollNeeded(pieceToAttack: greatestThreatMove.pieceToMove.type))/6.0
				let	moveBenefit = Double(greatestThreatMove.pieceToMove.pieceValue) * attackProb
					allMovesToTarget.append(AIMove(pieceToMove: b, attackedPiece: nil, oldPos: b.location, newPos: move, isAttackMove: false, moveBenefit:moveBenefit))
				}
			}
		}
		
	}
			//find attack with the best move benefit available
				var bestAttack:AIMove?
				var bestAttackBen:Double = 0.0
				var nextBestAttackBen:Double = 0.0
				var bestMove:AIMove?
				var bestMoveBen:Double = 0.0

			for a in allMovesToTarget{
				//print("move benefit: \(a.moveBenefit)")
				//print("is attack?: \(a.isAttackMove)")

				if (a.isAttackMove){
					if (a.moveBenefit > bestAttackBen){
						nextBestAttackBen = bestAttackBen//might not be correct as most pieces an only attack once
						bestAttackBen = a.moveBenefit
						bestAttack = a
					}
				} else {
					if (a.moveBenefit > bestMoveBen){
						bestMoveBen = a.moveBenefit
						bestMove = a
					}
				}

			}
	

	if (turnCounter == 2){//find best move or attack based on benefit
		defenseMove = (bestAttackBen + nextBestAttackBen > bestMoveBen) ? bestAttack : bestMove
	} else if (turnCounter == 3){
		if (bestAttack != nil){//on the second turn if AI has attack, do it
			defenseMove = bestAttack
		} else {//worst case would be moving king somewhere
			defenseMove = bestMove
		}
	} 	
	if (defenseMove == nil){
		
	}
	
	//print("king in danger! suggested move: move\(defenseMove?.pieceToMove.type) at \(defenseMove?.oldPos) to \(defenseMove?.newPos). This move is an attack: \(defenseMove?.isAttackMove)")
	
	
	let end = NSDate()
	let _: Double = end.timeIntervalSince(start as Date) // <<<<< Difference in seconds (double)
	
	//print("king defense took \(timeInterval) seconds")
	return defenseMove!
}
//**finds the greatest threat move based on the move that has the greatest benefit (could sort by largest and return first element)
//sees if there's a single move that eliminates all threats to king, if not will find move with largest reduction
//if no improvements, will look for hero pieces that can attack, save to array
//if no hero piece, will look for pieces that can move then attack threat piece
//add all moves to array
//if tc=2, see if it's better to move or attack
//if tc=3, attack has priority


//returns an array of cells (neighboring AI king) contains an opponents piece, ready to attack
func cellsCanAttackAIKing(board:Board) -> [Int]?{
	var kingCellsInDanger: [Int] = AIKing.getSurroundingCells(board: board)
	var i: Int = 0
	var j: Int = 0 //adjust index based on how many objects have been removed
	
	for c in kingCellsInDanger{
		if (board.getPieceAtLocation(location: c) == nil || board.getPieceAtLocation(location: c)?.team == Team.Black){
			//only objects in array should be indexes of cells occupied by enemy (white) pieces
			kingCellsInDanger.remove(at: i-j)
			j += 1
		}
		i += 1
	}
	if kingCellsInDanger.count > 0 {
		return kingCellsInDanger
	}
	return nil
}
//empty cells near king

func getKingRescueMove(board:Board,cellsInDanger:[Int], turnCounter: Int)->AIMove{
	//if there are any pieces ready to attack King, find the best use of AIs two turns
	//if first turn, decide if better to attack twice with two pieces (if possible) or move a more powerful piece then attack
	//if second turn, attack with most powerful piece regardless
	var kingAttacker: Piece = board.getPieceAtLocation(location: cellsInDanger.first!)!
	for i in cellsInDanger{
		if ((board.getPieceAtLocation(location: i)?.pieceValue)! > kingAttacker.pieceValue){
			kingAttacker = (board.getPieceAtLocation(location: i))!
		}
	}
	var rescueMoves: [AIMove] = []
	if (turnCounter == 2){
		var surroundingCells = kingAttacker.getSurroundingCells(board: board)
		var i: Int = 0
		var j: Int = 0 //adjust index based on how many objects have been removed
		for s in surroundingCells{
			if (board.getPieceAtLocation(location: s) == nil || board.getPieceAtLocation(location: s)?.team != Team.Black){
				//only objects in array should be indexes of cells occupied by enemy (white) pieces
				surroundingCells.remove(at: i-j)
				j += 1
			}
			i += 1
		}
		for s in surroundingCells{
			let heroPiece: Piece = board.getPieceAtLocation(location: s)!
			if (heroPiece.team == Team.Black){//attack risk should really only be considered if a piece can attack you back
				let attackBenefit:Double = Double(kingAttacker.pieceValue) * Double(7 - heroPiece.getMinRollNeeded(pieceToAttack: kingAttacker.type))/6.0
				let attackRisk:Double = Double(heroPiece.pieceValue) * Double(7 - kingAttacker.getMinRollNeeded(pieceToAttack: heroPiece.type))/6.0
				//print("The benefit of moving \(heroPiece.type) at \(heroPiece.location) to \(attackBenefit - attackRisk)")

				rescueMoves.append(AIMove(pieceToMove: heroPiece, attackedPiece: kingAttacker, oldPos: s, newPos: kingAttacker.location, isAttackMove: true, moveBenefit: attackBenefit - attackRisk))
			}
		}
		for b in board.blackPieces{//get AI pieces that can move then attack kingattacker
			for lm in getLegalMovesForPiece(board: board, thisPiece: b){
				if surroundingCells.contains(lm){
					let attackBenefit:Double = Double(kingAttacker.pieceValue) * Double(7 - b.getMinRollNeeded(pieceToAttack: kingAttacker.type))/6.0
					let attackRisk:Double = Double(b.pieceValue) * Double(7 - kingAttacker.getMinRollNeeded(pieceToAttack: b.type))/6.0
					//print("The benefit of moving \(b.type) at \(b.location) to \(attackBenefit - attackRisk)")
					rescueMoves.append(AIMove(pieceToMove: b, attackedPiece: nil, oldPos: b.location, newPos: lm, isAttackMove: false, moveBenefit: attackBenefit - attackRisk))
				}
			}
		}

		var bestAttk: AIMove = rescueMoves.first!
		var bestAttkVal: Double = 0.0
		var nextBestAttkVal: Double = 0.0
		var bestMove: AIMove?
		var bestMoveVal: Double = 0.0
		for r in rescueMoves{
			if (r.isAttackMove){
				if(r.moveBenefit > bestAttkVal){
					nextBestAttkVal = bestAttkVal
					bestAttk = r
					bestAttkVal = r.moveBenefit
				} else if (r.moveBenefit < bestAttkVal && r.moveBenefit > nextBestAttkVal){
					nextBestAttkVal = r.moveBenefit
				}
			} else {
				if(r.moveBenefit > bestMoveVal){
					bestMove = r
					bestMoveVal = r.moveBenefit
				}
			}
			if (bestMoveVal > bestAttkVal + nextBestAttkVal){
				return bestMove!
			} else {
				return bestAttk
			}

		}
	} else if (turnCounter == 3){
		var surroundingCells = kingAttacker.getSurroundingCells(board: board)
		var i: Int = 0
		var j: Int = 0 //adjust index based on how many objects have been removed
		for s in surroundingCells{
			if (board.getPieceAtLocation(location: s) == nil || board.getPieceAtLocation(location: s)?.team != Team.Black){
				//only objects in array should be indexes of cells occupied by enemy (white) pieces
				surroundingCells.remove(at: i-j)
				j += 1
			}
			i += 1
		}
		for s in surroundingCells{
			let heroPiece: Piece = board.getPieceAtLocation(location: s)!
			if (heroPiece.team == Team.Black && heroPiece.getCanAttack()){//attack risk should really only be considered if a piece can attack you back
				let attackBenefit:Double = Double(kingAttacker.pieceValue) * Double(7 - heroPiece.getMinRollNeeded(pieceToAttack: kingAttacker.type))/6.0
				let attackRisk:Double = Double(heroPiece.pieceValue) * Double(7 - kingAttacker.getMinRollNeeded(pieceToAttack: heroPiece.type))/6.0
				//print("The benefit of moving \(heroPiece.type) at \(heroPiece.location) to \(attackBenefit - attackRisk)")

				rescueMoves.append(AIMove(pieceToMove: heroPiece, attackedPiece: kingAttacker, oldPos: s, newPos: kingAttacker.location, isAttackMove: true, moveBenefit: attackBenefit - attackRisk))
			}
		}
		var bestAttk: AIMove?
		var bestAttkVal: Double = 0.0
		for r in rescueMoves{
				if(r.moveBenefit > bestAttkVal){
					bestAttkVal = r.moveBenefit
					bestAttk = r
			}
		}
		return bestAttk!
	}
	return rescueMoves.first!
}


func getLegalMovesForPiece(board:Board,thisPiece:Piece)->[Int]{
	
		var legalMovesForPiece = [Int]()
		for um in thisPiece.getUnfilteredMoves(board: board){
			if (thisPiece.getCanMove() && board.getPieceAtLocation(location:um) == nil){
					legalMovesForPiece.append(um)
				}
			if (thisPiece.getCanAttack() && board.getPieceAtLocation(location:um) != nil && board.getPieceAtLocation(location:um)?.team != thisPiece.team){
				legalMovesForPiece.append(um)
			}
		}
	return legalMovesForPiece
}

func getBestLegalMoves(board:Board,thisTeam:Team,turnCounter:Int)->[AIMove]{
	//creates AImove objects for each of AIs possible legal moves, calculates benefit
	//returns an array of each AImove object
	let teamsPieces = (thisTeam == Team.Black) ? board.blackPieces : board.whitePieces
	let otherTeamsPieces = (thisTeam == Team.Black) ? board.whitePieces : board.blackPieces
	//can return
	var availableMoves = [AIMove]()
	
	for p in teamsPieces{

		if (p.getCanAttack()){
			var bestMove: Int = p.location
			var largestAttackBenefit: Double = 0.0
			for s in (p.getSurroundingCells(board: board)){//finds largest benefit of attack moves around piece
				let pieceAtCell: Piece? = board.getPieceAtLocation(location: s)
				if (pieceAtCell != nil && pieceAtCell?.team != thisTeam){

					//print("piece can attack piece at \(s)")
					let attackProb: Double = Double(7 - p.getMinRollNeeded(pieceToAttack: pieceAtCell!.type))/6.0
					let currentBenefit: Double = attackProb * Double(pieceAtCell!.pieceValue)
					if (currentBenefit > largestAttackBenefit){
						bestMove = s
						largestAttackBenefit = currentBenefit
					availableMoves.append(AIMove(pieceToMove: p, attackedPiece: pieceAtCell, oldPos: p.location, newPos: bestMove, isAttackMove: true,moveBenefit:largestAttackBenefit))
					}

				}
			}
		}
		//now have largest benefit of attacking without moving first
		if (p.getCanMove()){
			var bestMove: Int = p.location
			var largestMoveBenefit: Double = 0.0
			for lm1 in getLegalMovesForPiece(board: board, thisPiece: p){//finds largest benefit of all legal moves
				//check if making this move exposes king, decrease benefit of move
				
				var moveExposesKing:Bool = false
				let oldPieceLocation: Int = p.location
				let oldKingThreatsCount: Int = getKingThreats(board: board).count
				let oldVulnerableCellCount: Int = getKingsVulnerableCells(board: board).count
				p.changeLocation(location: lm1)//temp set piece at location to consider whether king in more danger after move
				moveExposesKing = (getKingThreats(board: board).count > oldKingThreatsCount || getKingsVulnerableCells(board: board).count > oldVulnerableCellCount) ? true : false
				p.changeLocation(location: oldPieceLocation) //change back
	
				let firstLMPiece: Piece? = board.getPieceAtLocation(location: lm1)
				if (firstLMPiece == nil && !moveExposesKing){
					var attackProb: Double = 0.0 // the chance this piece will capture another
					let denominator: Double = 6.0
					let rowIncentive: Double = Double(lm1 / 8) / 100.0 //more benefit to spots further down board
					var neighboringPiecesArray = [Piece]()
					for otp in otherTeamsPieces {//builds array of other teams pieces neighboring legal move iteration
						let dist = getTileIndexDistance(fromLocation: lm1, toLocation: otp.location)
						if (dist == 1){
							neighboringPiecesArray.append(otp)
						}
					}

					for np in neighboringPiecesArray{//calculates the greatest move benefit of all the pieces neighboring legal move
						attackProb = Double(7 - p.getMinRollNeeded(pieceToAttack: np.type))/denominator
						var currentMaxBenefit = 0.0
						if (turnCounter == 2){
							currentMaxBenefit = (Double(np.pieceValue) * attackProb + rowIncentive)/2
						} else {
							currentMaxBenefit = ((Double(np.pieceValue) * attackProb)/2 + rowIncentive)/2
						}
						if (currentMaxBenefit >= largestMoveBenefit){
							bestMove = lm1
							largestMoveBenefit = currentMaxBenefit
						}
						
					}
					p.changeLocation(location: lm1)//temp set piece at location to consider whether king in more danger after move

					for lm2 in getLegalMovesForPiece(board: board, thisPiece: p){//finds largest benefit of all legal moves
						if (board.getPieceAtLocation(location: lm2) == nil){
							var attackProb: Double = 0.0 // the chance this piece will capture another
							let denominator: Double = 6.0
							let rowIncentive: Double = Double(lm1 / 8) / 100.0 //more benefit to spots further down board
							var neighboringPiecesArray = [Piece]()
							for otp in otherTeamsPieces {//builds array of other teams pieces neighboring legal move iteration
								let dist = getTileIndexDistance(fromLocation: lm2, toLocation: otp.location)
								if (dist == 1){
									neighboringPiecesArray.append(otp)
								}
							}
							for np in neighboringPiecesArray{//calculates the greatest move benefit of all the pieces neighboring legal move
								attackProb = Double(7 - p.getMinRollNeeded(pieceToAttack: np.type))/denominator
								var currentMaxBenefit = 0.0
								if (turnCounter == 2){
									currentMaxBenefit = (Double(np.pieceValue) * attackProb + rowIncentive)/2
								} else {
									currentMaxBenefit = ((Double(np.pieceValue) * attackProb)/2 + rowIncentive)/2
								}
								if (currentMaxBenefit > largestMoveBenefit){
									bestMove = lm1
									largestMoveBenefit = currentMaxBenefit
								}

							}

						}
					}
					p.changeLocation(location: oldPieceLocation )

				}
				
			}
			if (largestMoveBenefit == 0){
				for f in board.aiFirstWavePieces{
					for lm in getLegalMovesForPiece(board: board, thisPiece: f){
						if (board.getPieceAtLocation(location: lm) == nil){
							let randomVal = Double(GKRandomDistribution.init(lowestValue: 0, highestValue: 10).nextInt())
							let oldRow = f.location / 8
							let newRow = lm / 8
							//print("random ben: \(randomBenefit)")
							if (newRow > oldRow){//don't add any moves that have piece moving backward
								availableMoves.append(AIMove(pieceToMove: f, attackedPiece: nil, oldPos: f.location, newPos: lm, isAttackMove: false, moveBenefit:randomVal))

							}
						}

					}
				}
			} else if (largestMoveBenefit > 0) {
				availableMoves.append(AIMove(pieceToMove: p, attackedPiece: nil, oldPos: p.location, newPos: bestMove, isAttackMove: false,moveBenefit:largestMoveBenefit))
			}
		}
				//print("considering \(p.type) to \(bestMove) to attack \(attkPiece)")

	}
//	for a in availableMoves{
//		print("\(a.isAttackMove ? "attack \(a.attackedPiece) at":"move to") \(a.newPos) with benefit \(a.moveBenefit)")
//	}
	return availableMoves
}

func getPiecesDistance(firstPiece:Piece,secondPiece:Piece) ->Int {//returns shortest distance (in cells) between two given pieces
	let firstPieceRow = firstPiece.location / 8
	let secondPieceRow = secondPiece.location / 8
	let firstPieceCol = firstPiece.location % 8
	let secondPieceCol = secondPiece.location % 8
	
	let rowDist = abs(firstPieceRow-secondPieceRow)
	let colDist = abs(firstPieceCol-secondPieceCol)
	
	if (rowDist >= colDist){//distance is the greater value between how many rows/cols two pieces are apart
		return rowDist
	}
	return colDist
}

func getOppsNearKing(board:Board,king:Piece) ->[Piece] {//not currently used
	//returns array of opponents pieces within a two cell radius
	//can be added/tweaked for better King defense
	var oppArray = king.team == Team.Black ? board.blackPieces : board.whitePieces
	var oppsNearKingArray = [Piece]();
	for i in oppArray {
		if (getPiecesDistance(firstPiece: king, secondPiece: i) == 3){
			oppsNearKingArray.append(i)
		}
	}
	return oppsNearKingArray
}

func getTileIndexDistance(fromLocation:Int,toLocation:Int) -> Int {//accepts two ints corresponding to tile location and returns the distance (in cells)
	let toLocationRow = fromLocation / 8
	let fromLocationRow = toLocation / 8
	let toLocationCol = fromLocation % 8
	let fromLocationCol = toLocation % 8
	
	let rowDist = abs(toLocationRow-fromLocationRow)
	let colDist = abs(toLocationCol-fromLocationCol)
	
	if (rowDist >= colDist){
		return rowDist
	}
	return colDist
}

//return the appropriate move based on difficulty level
func getMoveByDifficulty(movesArray:[AIMove],difficulty:Int)->AIMove{
	var chosenAIMove:AIMove = movesArray.first!

	switch difficulty {
		case 0://picks random element from moves array
			//should be reconfigured so that it only picks a random element with a move benefit > 0
			var movesArray2 = [AIMove]();
			for m in movesArray{
				if m.moveBenefit >= 0{
					movesArray2.append(m)
				}
			}
		chosenAIMove = movesArray2.randomElement()!
		print("easy mode")
		
		
		case 1://idea: create a new array that holds the middle 1/3 moves sorted by move benefit
		//for example if moves array has 3 elements m1 with move benefit 1, m2 with 2, and m3 with 3, the new array would only hold m2
		//hint on how to implement: your new array's size would be 1/3 of old array,
		//once you have the new array, simply call array.randomelement()
			
			var movesArray2 = [AIMove]();
			var sum:Double = 0
			var mean:Double = 0
			
			for m in movesArray{
				if m.moveBenefit > 0{
					sum = sum + m.moveBenefit
				}
			}
			mean = sum/Double(movesArray2.capacity)
			mean = mean + mean/2
			
			for m in movesArray{
				if m.moveBenefit >= mean{
					movesArray2.append(m)
				}
			}
			
		chosenAIMove = movesArray2.randomElement()!
		print("medium mode")
		case 2:
			for m in movesArray{//finds and returns the aimove with the greatest movebenefit
				if (m.moveBenefit > chosenAIMove.moveBenefit){
					chosenAIMove = m
				}
			}
		print("hard mode")
		default:
		print("something went wrong")
	}
	return chosenAIMove
}
