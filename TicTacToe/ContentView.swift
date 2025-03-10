//
//  ContentView.swift
//  TicTacToe
//
//  Created by IV. on 09/03/25.
//

import SwiftUI

extension Color {
  init(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)

    if hexSanitized.hasPrefix("#") {
      hexSanitized.removeFirst()
    }

    let scanner = Scanner(string: hexSanitized)
    var rgb: UInt64 = 0

    if scanner.scanHexInt64(&rgb) {
      let red = Double((rgb & 0xFF0000) >> 16) / 255.0
      let green = Double((rgb & 0x00FF00) >> 8) / 255.0
      let blue = Double(rgb & 0x0000FF) / 255.0
      self.init(red: red, green: green, blue: blue)
    } else {
      self.init(red: 0, green: 0, blue: 0)  // Deixa preto se o valor fornecido for invalido.
    }
  }
}

struct ContentView: View {
  @State private var board: [[String]] = Array(repeating: Array(repeating: "", count: 3), count: 3)
  @State private var currentPlayer: String = "X"
  @State private var winner: String? = nil
  @State private var consecutivesWins: Int = 0
  @State private var isFirstAIMove: Bool = true
  // Não consigo passar do nivel 5. D:
  @State private var depthLimit: Int = 5  // Limite de profundidade para a IA (menor = mais fácil)

  var body: some View {
    VStack {
      Text(messageText)
        .font(.title)
        .foregroundStyle(Color(hex: "#0e0e0e"))

      Text("Vitórias seguidas: \(consecutivesWins)")
        .font(.headline)
        .foregroundStyle(Color(hex: "#0e0e0e"))

      Text("Nivel de dificuldade: \(depthLimit - 4)")
        .font(.headline)
        .foregroundStyle(Color(hex: "#0e0e0e"))

      // Tabuleiro
      ForEach(0..<3, id: \.self) { row in
        HStack {
          ForEach(0..<3, id: \.self) { col in
            Button(action: {
              makeMove(row: row, col: col)
            }) {
              Text(board[row][col])
                .font(.system(size: 50))
                .frame(width: 80, height: 80)
                .foregroundStyle(Color(hex: "#0e0e0e"))
            }
            .disabled(board[row][col] != "" || winner != nil)
            .background(Color(hex: "#efefff"))
            .shadow(radius: 3)
          }
        }
      }

      // Botão de Reiniciar
      Button(action: resetToDefault) {
        Text("Reiniciar")
          .foregroundStyle(.white)  // ou, se preferir, .foregroundColor(.black)
          .padding(5)
          .background(Color(hex: "#0e0e0e"))
          .cornerRadius(8)
      }
      .buttonStyle(PlainButtonStyle())
      .padding()
    }
    .frame(
      minWidth: 400,
      idealWidth: 1366,
      maxWidth: 1920,
      minHeight: 600,
      idealHeight: 733,
      maxHeight: 1080,
      alignment: .center
    )
    .background(Color(hex: "#f0f0ff"))
  }

  var messageText: String {
    if let winner = winner {
      return winner == "Empate" ? "Empate!" : "\(winner) venceu! 🎉"
    } else {
      return "Vez de: \(currentPlayer)"
    }
  }

  func makeMove(row: Int, col: Int) {
    guard board[row][col] == "" && winner == nil else { return }

    // Jogada do jogador
    board[row][col] = currentPlayer
    if checkWinner(player: currentPlayer) {
      if currentPlayer == "X" {
        winner = currentPlayer
        consecutivesWins += 1
        depthLimit += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {  // Pequeno atraso antes de começar um novo jogo.
          resetGame()
        }
        return
      } else {
        winner = currentPlayer
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {  // Pequeno atraso antes de começar um novo jogo.
          resetToDefault()
        }
        return
      }
    }

    // Verifica se tem um empate
    if board.flatMap({ $0 }).contains("") == false {
      winner = "Empate"
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {  // Pequeno atraso antes de começar um novo jogo.
        resetGame()
      }
      return
    }

    // Muda o jogador
    currentPlayer = currentPlayer == "X" ? "O" : "X"

    // Se for a vez da IA (jogador "O")
    if currentPlayer == "O" && winner == nil {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {  // Pequeno atraso para simular o pensamento da IA...
        aiMove()
      }
    }
  }

  func aiMove() {
    guard winner == nil else { return }

    let bestMove = findBestMove()
    // Se não houver um movimento válido, verifica se ouve um empate.
    guard bestMove.row >= 0, bestMove.col >= 0 else {
      if board.flatMap({ $0 }).contains("") == false {
        winner = "Empate"
      }
      return
    }

    board[bestMove.row][bestMove.col] = "O"

    if checkWinner(player: "O") {
      winner = "O"
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {  // Pequeno atraso antes de começar um novo jogo.
        resetToDefault()
      }
    } else if board.flatMap({ $0 }).contains("") == false {
      winner = "Empate"
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {  // Pequeno atraso antes de começar um novo jogo.
        resetGame()
      }
    } else {
      currentPlayer = "X"
    }

    isFirstAIMove = false
  }

  // Limita a profundidade do Minimax para tornar a IA mais fácil, afinal, quem quer jogar contra alguém que não da pra ganhar?
  func findBestMove() -> (row: Int, col: Int) {
    var bestScore = Int.min
    var move: (row: Int, col: Int) = (-1, -1)

    for row in 0..<3 {
      for col in 0..<3 {
        if board[row][col] == "" {  // Verifique se a célula está vazia
          board[row][col] = "O"  // Simula a jogada da IA
          let score = minimax(board: board, depth: 0, isMaximizing: false)
          board[row][col] = ""  // Desfaz a simulação

          if score > bestScore {
            bestScore = score
            move = (row, col)
          }
        }
      }
    }
    return move
  }

  // Algoritmo Minimax que retorna uma pontuação para o estado do tabuleiro
  func minimax(board: [[String]], depth: Int, isMaximizing: Bool) -> Int {
    if depth > depthLimit {
      return 0  // Se atingir o limite de profundidade, retorna um valor neutro.
    }

    if let result = evaluateBoard(board: board) {
      return result
    }

    if isMaximizing {
      var bestScore = Int.min
      for row in 0..<3 {
        for col in 0..<3 {
          if board[row][col] == "" {
            var newBoard = board
            newBoard[row][col] = "O"
            let score = minimax(board: newBoard, depth: depth + 1, isMaximizing: false)
            bestScore = max(bestScore, score)
          }
        }
      }
      return bestScore
    } else {
      var bestScore = Int.max
      for row in 0..<3 {
        for col in 0..<3 {
          if board[row][col] == "" {
            var newBoard = board
            newBoard[row][col] = "X"
            let score = minimax(board: newBoard, depth: depth + 1, isMaximizing: true)
            bestScore = min(bestScore, score)
          }
        }
      }
      return bestScore
    }
  }

  // Avalia o estado atual do tabuleiro.
  func evaluateBoard(board: [[String]]) -> Int? {
    if checkWinner(board: board, player: "O") {
      return 1
    }
    if checkWinner(board: board, player: "X") {
      return -1
    }
    if board.flatMap({ $0 }).contains("") == false {
      return 0
    }

    let randomNum = Int.random(in: 0...100)

    // Pequena chance da IA fazer um movimento aleatorio.
    if randomNum >= 95 && !isFirstAIMove {
      return Int.random(in: -1...1)  // Avaliação aleatória para a IA em profundidades altas
    }

    return nil
  }

  // Verifica se o jogador venceu em um determinado tabuleiro
  func checkWinner(board: [[String]], player: String) -> Bool {
    for i in 0..<3 {
      if board[i] == [player, player, player] { return true }
      if board.map({ $0[i] }) == [player, player, player] { return true }
    }
    if (0..<3).allSatisfy({ board[$0][$0] == player }) { return true }
    if (0..<3).allSatisfy({ board[$0][2 - $0] == player }) { return true }
    return false
  }

  // Versão que utiliza o tabuleiro atual (state)
  func checkWinner(player: String) -> Bool {
    return checkWinner(board: board, player: player)
  }

  func resetGame() {
    board = Array(repeating: Array(repeating: "", count: 3), count: 3)
    currentPlayer = "X"
    winner = nil
    isFirstAIMove = true
  }

  func resetToDefault() {
    board = Array(repeating: Array(repeating: "", count: 3), count: 3)
    currentPlayer = "X"
    winner = nil
    consecutivesWins = 0
    depthLimit = 5
    isFirstAIMove = true
  }
}

#Preview {
  ContentView()
}
