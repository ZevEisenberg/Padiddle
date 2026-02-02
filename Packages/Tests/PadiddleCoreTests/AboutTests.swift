import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import SnapshotTestingCustomDump
import TestHelpers
import Testing

@testable import PadiddleCore

@Suite(.snapshots(record: .failed))
struct AboutTests {
  @Test(.dependencies {
    $0.locale = Locale(identifier: "en")
  })
  func initialization() async {
    let model = await AboutModel()
    let html = model.html

    assertInlineSnapshot(of: html, as: .customDump) {
      #"""
      """
      <html>
          <head>
              <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
              <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
              <style type="text/css">

                  /* http://meyerweb.com/eric/tools/css/reset/
                   v2.0 | 20110126
                   License: none (public domain)
                   */

              html, body, div, span, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, section, summary, time, mark, audio, video {
                  margin: 0;
                  padding: 0;
                  border: 0;
                  font-size: 100%;
                  vertical-align: baseline;
              }

              body {
                  line-height: 1;
              }
              ol, ul {
                  list-style: none;
              }
              blockquote, q {
                  quotes: none;
              }
              blockquote:before, blockquote:after,
              q:before, q:after {
                  content: '';
                  content: none;
              }
              table {
                  border-collapse: collapse;
                  border-spacing: 0;
              }

              /* end reset */

              body {
                  background-color: #FFFFFF;
                  padding: 20px;
                  -webkit-user-select: none;
                  color: #181818;
                  -webkit-text-size-adjust: none; /* reflow text on rotate */
              }

              h1 {
                  font: -apple-system-headline;
                  color: #ff3b30;
                  line-height: 2.0;
              }

              p {
                  font: -apple-system-body;
                  padding: 0px;
                  margin:0px 0px 20px 0px;
                  line-height: 1.5;
              }

              a {
                  color: #007aff;
              }

              ul {
                  line-height: 1.5;
                  padding: 0px 0px 20px 20px;
              }

              .dedication {
                  font: -apple-system-body;
                  font-style: italic;
              }

              .footer {
                  font: -apple-system-caption;
              }

              /* images */

              #recordButton {
                  vertical-align: middle;
                  position: relative;
                  top: -2pt;
                  width: 2em;
                  height: 2em;
              }

              #colorButton {
                  vertical-align: middle;
                  position: relative;
                  top: -2pt;
                  width: 2em;
                  height: 2em;
              }

              #deviceImage {
                  margin-left: auto;
                  margin-right: auto;
                  display: block;
                  width: 80%;
                  max-width: 200px;
              }

              @media (prefers-color-scheme: dark) {
                  body {
                      background-color: #121212;
                      color: #D3D3D3;
                  }

                  h1 {
                      color: #FF4E45;
                      letter-spacing: 0.08em;
                  }
              }
                  </style>
          </head>
          <body>
              <h1>Instructions</h1>
              <p>Tap the <img id="recordButton" src="padiddle-asset://recordButton" alt="picture of the app&rsquo;s Record button" /> button, then spin your iPhone around like this:</p>
              <p><img id="deviceImage" src="padiddle-asset://deviceImage" alt="iOS device spinning on a person&rsquo;s finger" /></p>
              <p>Tap the <img id="colorButton" src="padiddle-asset://colorButton" alt="picture of the app&rsquo;s Color button" /> button to choose from a library of color schemes.</p>
              <h1>Support</h1>
              <p>Questions? Comments? Feedback? I would love to hear from you! Contact me on <a href="https://mastodon.social/@ZevEisenberg">Mastodon</a>, or check out the FAQ on the <a href="https://ZevEisenberg.com/#padiddle-faq">website</a>.</p>
              <h1>Credits</h1>
              <p>Created by <a href="https://zeveisenberg.com">Zev Eisenberg</a></p>
              <p>Thanks to my awesome beta testers for their feedback and ideas:</p>
              <p>Avner Eisenberg &bull; Cheryl Pedersen &bull; David Tatzel &bull; Laurent Sauerwein</p>
              <p>Special thanks to Ian McClure, Kyler Hanzie, and Andy Hamm for their design guidance, and to Cameron Pulsford for his help in shoring up some nasty memory leaks.</p>
              <p class="dedication">Padiddle is dedicated to the memory of Luke Wilson, the brilliant and creative juggler who gave me the idea of drawing pictures with an iPad while padiddling it. Luke was my first beta tester, and many of his suggestions and refinements are reflected in the app as it exists today. He will be missed.</p>
              <p class="footer">Padiddle 1.0.0 (0001)<br />&copy; 2014 Zev Eisenberg.</p>
          </body>
      </html>

      """
      """#
    }
  }

  @Test(.dependencies {
    $0.locale = Locale(identifier: "fr")
  })
  func localization() async {
    let model = await AboutModel()
    let html = model.html

    assertInlineSnapshot(of: html, as: .customDump) {
      #"""
      """
      <html>
          <head>
              <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
              <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
              <style type="text/css">

                  /* http://meyerweb.com/eric/tools/css/reset/
                   v2.0 | 20110126
                   License: none (public domain)
                   */

              html, body, div, span, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, section, summary, time, mark, audio, video {
                  margin: 0;
                  padding: 0;
                  border: 0;
                  font-size: 100%;
                  vertical-align: baseline;
              }

              body {
                  line-height: 1;
              }
              ol, ul {
                  list-style: none;
              }
              blockquote, q {
                  quotes: none;
              }
              blockquote:before, blockquote:after,
              q:before, q:after {
                  content: '';
                  content: none;
              }
              table {
                  border-collapse: collapse;
                  border-spacing: 0;
              }

              /* end reset */

              body {
                  background-color: #FFFFFF;
                  padding: 20px;
                  -webkit-user-select: none;
                  color: #181818;
                  -webkit-text-size-adjust: none; /* reflow text on rotate */
              }

              h1 {
                  font: -apple-system-headline;
                  color: #ff3b30;
                  line-height: 2.0;
              }

              p {
                  font: -apple-system-body;
                  padding: 0px;
                  margin:0px 0px 20px 0px;
                  line-height: 1.5;
              }

              a {
                  color: #007aff;
              }

              ul {
                  line-height: 1.5;
                  padding: 0px 0px 20px 20px;
              }

              .dedication {
                  font: -apple-system-body;
                  font-style: italic;
              }

              .footer {
                  font: -apple-system-caption;
              }

              /* images */

              #recordButton {
                  vertical-align: middle;
                  position: relative;
                  top: -2pt;
                  width: 2em;
                  height: 2em;
              }

              #colorButton {
                  vertical-align: middle;
                  position: relative;
                  top: -2pt;
                  width: 2em;
                  height: 2em;
              }

              #deviceImage {
                  margin-left: auto;
                  margin-right: auto;
                  display: block;
                  width: 80%;
                  max-width: 200px;
              }

              @media (prefers-color-scheme: dark) {
                  body {
                      background-color: #121212;
                      color: #D3D3D3;
                  }

                  h1 {
                      color: #FF4E45;
                      letter-spacing: 0.08em;
                  }
              }
                  </style>
          </head>
          <body>
              <!--
               In France, : ; ? and ! are always preceded by a thin non-breaking space space: &nbsp;.
               Source: http://jkorpela.fi/html/french.html
               -->
              <h1>Instructions</h1>
              <p>Touchez le bouton <img id="recordButton" src="padiddle-asset://recordButton" alt="Image du bouton Enregistrement de l&rsquo;application" />, puis tournez votre iPhone comme suit&nbsp;:</p>
              <p><img id="deviceImage" src="padiddle-asset://deviceImage" alt="Appareil iOS tournant sur le doigt d&rsquo;une personne" /></p>
              <p>Touchez le bouton <img id="colorButton" src="padiddle-asset://colorButton" alt="Image du bouton Couleur de l&rsquo;application" /> pour choisir un thème de couleur dans la bibliothèque.</p>
              <h1>Support</h1>
              <p>Des Questions&nbsp;? Commentaires&nbsp;? Suggestions&nbsp;? Je voudrais vous entendre&nbsp;! Contactez-moi sur <a href="https://mastodon.social/@ZevEisenberg">Mastodon</a> et consultez la FAQ sur le <a href="https://ZevEisenberg.com/#padiddle-faq">site</a>.</p>
              <h1>Cr&eacute;dits</h1>
              <p>Cr&eacute;e par <a href="https://zeveisenberg.com">Zev Eisenberg</a></p>
              <p>Merci &agrave; mes b&ecirc;ta-testeurs formidables pour leurs retours d&rsquo;informations et id&eacute;es&nbsp;:</p>
              <p>Avner Eisenberg &bull; Cheryl Pedersen &bull; David Tatzel &bull; Laurent Sauerwein</p>
              <p>Merci beaucoup &agrave; Ian McClure, Kyler Hanzie, et Andy Hamm pour leurs conseils pour la conception, et &agrave; Cameron Pulsford pour son aide pour r&eacute;parer une terrible fuite de m&eacute;moire.</p>
              <p>Traduite en fran&ccedil;ais par Cheryl Pedersen, David Mendels et Olivier Halligon.</p>
              <p class="dedication">Padiddle est d&eacute;di&eacute; à memoire de Luke Wilson, le jongleur dou&eacute; et cr&eacute;atif qui m&rsquo;a donn&eacute; l&rsquo;id&eacute;e de dessiner des images avec un iPad en faisant paddidle. Luke a &eacute;t&eacute; mon premier b&ecirc;ta-testeur, et beaucoup de ses suggestions et am&eacute;liorations se r&eacute;fl&eacute;tent dans ce que l&rsquo;application est aujourd&rsquo;hui devenue. Il va nous manquer.</p>
              <p class="footer">Padiddle 1.0.0 (0001)<br />&copy; 2014 Zev Eisenberg.</p>
          </body>
      </html>

      """
      """#
    }
  }
}
