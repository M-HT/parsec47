PARSEC47  readme.txt
for Windows98/2000/XP(要OpenGL)
ver. 0.2
(C) Kenta Cho

レトロな敵をモダンに倒せ。
レトロモダンハイスピードシューティング、PARSEC47。


○ インストール方法

p47_0_2.zipを適当なフォルダに展開してください。
その後、'p47.exe'を実行してください。
（マシンの速度が遅い場合は、'p47_lowres.bat'を実行してください。
  ゲームを低解像度で立ち上げます。）


○ 遊び方

 - 移動                  矢印キー, テンキー  / ジョイステック
 - ショット              [Z][左Ctrl]         / トリガ1, 4, 5, 8
 - スロー/ロール, ロック [X][左Alt][左Shift] / トリガ2, 3, 6, 7
 - ポーズ                [P]

キーボードかジョイスティックでステージを選んでください。
ショットキーでゲームを開始します。
全てのステージはエンドレスで、毎回乱数で生成されます。
全ての自機を失うとゲームオーバーです。

自機を操作して、敵を破壊してください。
スローキーを押している間、自機が遅くなります。

タイトル画面でスローキーを押すことで、
2つのゲームモードを切り替えることができます。
それぞれのゲームモードは、異なる弾幕パターンを備えています。

. ロールモード
スローキーを押している間、ロールショットエネルギーが貯まります。
ロールショットはスローキーを離すと発射されます。

. ロックモード
スローキーを押している間、前方の敵を狙うロックオンレーザーを
撃つことができます。

自機は200,000点および500,000点ごとに1機増えます。

以下のオプションが指定できます。
 -brightness n  画面の明るさを指定します(n = 0 - 100, デフォルト100)
 -luminous n    発光エフェクトの強さを指定します(n = 0 - 100, デフォルト0)
 -lowres        低解像度モードを利用します。
 -nosound       音を出力しません。
 -window        ウィンドウモードで起動します。
 -reverse       ショットとスローのキーを入れ替えます。
 -slowship      すべてのゲームモードで低速の自機を使用します。
 -nowait        意図的な処理落ちを発生させないようにします。


○ ご意見、ご感想

コメントなどは、cs8k-cyu@asahi-net.or.jp までお願いします。


○ ウェブページ

PARSEC47 webpage:
http://www.asahi-net.or.jp/~cs8k-cyu/windows/p47.html


○ 謝辞

PARSEC47はD言語で書かれています。
 D Programming Language
 http://www.digitalmars.com/d/index.html

BulletMLファイルのパースにlibBulletMLを利用しています。
 libBulletML
 http://user.ecc.u-tokyo.ac.jp/~s31552/wp/libbulletml/

画面の出力にはSimple DirectMedia Layerを利用しています。
 Simple DirectMedia Layer
 http://www.libsdl.org/

BGMとSEの出力にSDL_mixerとOgg Vorbis CODECを利用しています。
 SDL_mixer 1.2
 http://www.libsdl.org/projects/SDL_mixer/
 Vorbis.com
 http://www.vorbis.com/

DedicateDのD言語用OpenGL, SDLヘッダファイルおよび
D - portingのSDL_mixerヘッダファイルを利用しています。
 DedicateD
 http://int19h.tamb.ru/files.html
 D - porting
 http://user.ecc.u-tokyo.ac.jp/~s31552/wp/d/porting.html

乱数発生器にMersenne Twisterを利用しています。
 http://www.math.keio.ac.jp/matumoto/emt.html


○ ヒストリ

2004  1/ 1  ver. 0.2
            ロックモードの追加。
            弾幕の調整。
            弾の消失バグ修正。
2003 12/21  ver. 0.13
            '-slowship'オプションの追加。
            低速の弾は一定時間後消滅。
            画面リサイズ時のバグ修正。
2003 12/ 5  ver. 0.12
            敵の出現位置の調整。
            弾幕の調整。
2003 11/30  ver. 0.11
            ライン描画ルーチンの修正。
            フィールドサイズの調整。
            弾幕の調整。
            ロールショットの弱体化。
2003 11/29  ver. 0.1


○ ライセンス

PARSEC47はBSDスタイルライセンスのもと配布されます。

License
-------

Copyright 2003 Kenta Cho. All rights reserved. 

Redistribution and use in source and binary forms, 
with or without modification, are permitted provided that 
the following conditions are met: 

 1. Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer. 

 2. Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
