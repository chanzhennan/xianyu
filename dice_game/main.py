# -*- coding: utf-8 -*-
import random
import sys

from PyQt5.QtCore import QRect, QSize, Qt
from PyQt5.QtGui import *
from PyQt5.QtWidgets import *


class Player:
    def __init__(self, png):
        self.png = png
        self.won = 0
        self.even = 0


class DiceGame(QMainWindow):
    def __init__(self):
        super().__init__()
        self.width = 600
        self.height = 600
        self.round = 0

        self.setStyleSheet(
            "QMainWindow { border-image: url(background.jpg); "
            "background-repeat: no-repeat;"
            "background-position: center;}"
        )

        self.resize(self.width, self.height)

        # button
        self.startButton = QPushButton("Play", self)
        self.checkButton1 = QPushButton("P1 History", self)
        self.checkButton2 = QPushButton("P2 History", self)
        self.startButton.setFixedSize(100, 30)
        self.checkButton1.setFixedSize(100, 30)
        self.checkButton2.setFixedSize(100, 30)

        # label
        self.label = QLabel('Push button to start ', self)
        self.label.setAlignment(Qt.AlignCenter)
        self.label.setFixedSize(300, 30)
        self.label.setFont(QFont('Arial', 14))

        self.label1 = QLabel('player 1 ', self)
        self.label1.setFixedSize(200, 30)
        self.label1.setFont(QFont('Arial', 14))

        self.label2 = QLabel('player 2 ', self)
        self.label2.setFixedSize(200, 30)
        self.label2.setFont(QFont('Arial', 14))

        self.wonlabel = QLabel('player 2 ', self)
        self.wonlabel.setFixedSize(400, 30)
        self.wonlabel.setFont(QFont('Arial', 14))

        # player
        self.player1 = Player("")
        self.player2 = Player("")

        self.initUI()

    def initUI(self):
        self.setWindowTitle('双人骰子游戏')

        self.startButton.move((self.width + 100) / 4, 450)
        self.checkButton1.move((self.width + 100) / 4 + 150, 450)
        self.checkButton2.move((self.width + 100) / 4 + 150, 500)
        self.label.move(150, 150)
        self.label1.move((self.width + 100) / 4, 200)
        self.label2.move((self.width + 100) / 4, 250)
        self.wonlabel.move((self.width + 100) / 4, 350)
        self.startButton.clicked.connect(self.play_game)
        self.checkButton1.clicked.connect(self.show_play1)
        self.checkButton2.clicked.connect(self.show_play2)

    def show_play1(self):
        text = "player 1 won : %d, even : %d" % (
            self.player1.won,
            self.player1.even,
        )
        self.wonlabel.setText(text)

    def show_play2(self):
        text = "player 2 won : %d, even : %d" % (
            self.player2.won,
            self.player2.even,
        )
        self.wonlabel.setText(text)

    def play_game(self):
        self.round += 1
        player1 = random.randint(1, 6) + random.randint(1, 6)
        player2 = random.randint(1, 6) + random.randint(1, 6)
        result1 = 'player 1 : %d' % (player1)
        result2 = 'player 2 : %d' % (player2)
        text = 'Round : %d' % (self.round)

        if player1 > player2:
            self.player1.won += 1
            result3 = 'player 1 won'

        elif player2 > player1:
            self.player2.won += 1
            result3 = 'player 2 won'
        else:
            self.player1.even += 1
            self.player2.even += 1
            result = 'even'

        self.label.setText(text)
        self.label1.setText(result1)
        self.label2.setText(result2)


if __name__ == '__main__':
    app = QApplication(sys.argv)
    game = DiceGame()
    game.show()
    sys.exit(app.exec_())
