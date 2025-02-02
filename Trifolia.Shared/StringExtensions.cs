﻿using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Wordprocessing;
using DocumentFormat.OpenXml.Packaging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Trifolia.Config;
using Markdig;
using Trifolia.Logging;
using Trifolia.DB;

namespace Trifolia.Shared
{
    public static class StringExtensions
    {
        private static Regex invalidUtf8Characters = new Regex("[^\x00-\x7F]+");
        private static MarkdownPipeline mdPipeline = new Markdig.MarkdownPipelineBuilder().UseAdvancedExtensions().Build();

        private static void StylizeKeywords(OpenXmlElement openXmlElement)
        {
            var runs = openXmlElement.Descendants<Run>().ToList();

            foreach (var cRun in runs)
            {
                var cText = cRun.GetFirstChild<Text>();
                Regex regex = new Regex(" SHALL NOT | SHOULD NOT | MAY NOT | SHALL | SHOULD | MAY ");
                MatchCollection matches = regex.Matches(cText.Text);
                string[] split = regex.Split(cText.Text);
                List<OpenXmlElement> newElements = new List<OpenXmlElement>();
                if (split.Length > 1)
                {
                    var runParent = cRun.Parent != null ? cRun.Parent : openXmlElement.FirstChild;
                    for (var i = 0; i < split.Length; i++)
                    {
                        var newOtherRun = new Run(new Text(split[i]) { Space = SpaceProcessingModeValues.Preserve });
                        newElements.Add(newOtherRun);
                        if (i < split.Length - 1)
                        {
                            var newKeywordRun = new Run(
                                new RunProperties(new RunStyle()
                                {
                                    Val = "keyword"
                                }),
                                new Text(matches[i].Value) { Space = SpaceProcessingModeValues.Preserve });
                            newElements.Add(newKeywordRun);
                        }
                    }
                }
                for (var i = newElements.Count - 1; i >= 0; i--)
                {
                    cRun.Parent.InsertAfter(newElements[i], cRun);
                }
                if (newElements.Count > 0)
                    cRun.Parent.RemoveChild(cRun);
            }
        }

        public static string MarkdownToHtml(this string theString)
        {
            if (string.IsNullOrEmpty(theString))
                return theString;

            string html = Markdig.Markdown.ToHtml(theString, mdPipeline);
            return html;
        }

        public static OpenXmlElement MarkdownToOpenXml(this string theString, IObjectRepository tdb, MainDocumentPart mainPart, bool styleKeywords = false)
        {
            try
            {
                string input = theString;

                string html = MarkdownToHtml(input);
                var openXmlElement = html.HtmlToOpenXml(tdb, mainPart);

                if (styleKeywords)
                    StylizeKeywords(openXmlElement);

                return openXmlElement;
            }
            catch (Exception ex)
            {
                Log.For(typeof(StringExtensions)).Error("Error converting Markdown to OpenXml for the following Markdown:\r\n" + theString, ex);
                return new Body(
                    new Paragraph(
                        new Run(
                            new Text(theString))));
            }
        }

        public static OpenXmlElement HtmlToOpenXml(this string html, IObjectRepository tdb, MainDocumentPart mainPart)
        {
            HtmlToOpenXmlConverter converter = new HtmlToOpenXmlConverter(tdb, mainPart);
            return converter.Convert(html);
        }

        public static string XmlEncode(this string theString)
        {
            if (string.IsNullOrEmpty(theString))
                return theString;

            return new System.Xml.Linq.XText(theString).ToString();
        }

        public static string MakePlural(this string theString)
        {
            string[] oNounsES = new string[] { "echo", "hero", "potato", "veto" };
            string[] oNounS = new string[] { "auto", "memo", "pimento", "pro" };

            if (theString.EndsWith("y"))
            {
                return theString.Substring(0, theString.Length - 1) + "ies";
            }
            else if (theString.EndsWith("s") || theString.EndsWith("z") || theString.EndsWith("ch") || theString.EndsWith("sh") || theString.EndsWith("x"))
            {
                return theString + "es";
            }

            foreach (string cONounES in oNounsES)
            {
                if (theString.EndsWith(cONounES))
                    return theString + "es";
            }

            foreach (string cONounS in oNounS)
            {
                if (theString.EndsWith(cONounS))
                    return theString + "s";
            }

            return theString + "s";
        }

        public static string RemoveInvalidUtf8Characters(this string theString, string replacement = "")
        {
            return invalidUtf8Characters.Replace(theString, replacement);
        }

        // While an app specific salt is not the best practice for password based encryption, it's probably safe enough as long as it is truly uncommon.
        private static byte[] _salt = new byte[] { 31, 204, 205, 160, 43, 221, 154, 143, 145, 156, 160, 52, 8, 133, 53, 81, 10, 50, 108, 196, 150, 213, 27, 106, 227, 16, 25, 121, 252, 53, 46, 250, 68, 146, 57, 249, 4, 171, 122, 61, 50, 220, 253, 174, 18, 72, 65, 162, 221, 27, 86, 34, 241, 219, 88, 254, 25, 81, 184, 201, 61, 22, 6, 245 };

        /// <summary>
        /// Encrypt the given string using AES.  The string can be decrypted using DecryptStringAES().  The sharedSecret parameters must match.
        /// </summary>
        /// <param name="plainText">The text to encrypt.</param>
        /// <param name="sharedSecret">A password used to generate a key for encryption.</param>
        public static string EncryptStringAES(this string plainText)
        {
            if (string.IsNullOrEmpty(plainText))
                return plainText;
            if (string.IsNullOrEmpty(AppSettings.EncryptionSecret))
                throw new ArgumentNullException("appSettings/EncryptionSecret");

            string outStr = null;                       // Encrypted string to return
            RijndaelManaged aesAlg = null;              // RijndaelManaged object used to encrypt the data.

            try
            {
                // generate the key from the shared secret and the salt
                Rfc2898DeriveBytes key = new Rfc2898DeriveBytes(AppSettings.EncryptionSecret, _salt);

                // Create a RijndaelManaged object
                aesAlg = new RijndaelManaged();
                aesAlg.Key = key.GetBytes(aesAlg.KeySize / 8);

                // Create a decryptor to perform the stream transform.
                ICryptoTransform encryptor = aesAlg.CreateEncryptor(aesAlg.Key, aesAlg.IV);

                // Create the streams used for encryption.
                using (MemoryStream msEncrypt = new MemoryStream())
                {
                    // prepend the IV
                    msEncrypt.Write(BitConverter.GetBytes(aesAlg.IV.Length), 0, sizeof(int));
                    msEncrypt.Write(aesAlg.IV, 0, aesAlg.IV.Length);
                    using (CryptoStream csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
                    {
                        using (StreamWriter swEncrypt = new StreamWriter(csEncrypt))
                        {
                            //Write all data to the stream.
                            swEncrypt.Write(plainText);
                        }
                    }
                    outStr = Convert.ToBase64String(msEncrypt.ToArray());
                }
            }
            finally
            {
                // Clear the RijndaelManaged object.
                if (aesAlg != null)
                    aesAlg.Clear();
            }

            // Return the encrypted bytes from the memory stream.
            return outStr;
        }

        /// <summary>
        /// Decrypt the given string.  Assumes the string was encrypted using EncryptStringAES(), using an identical sharedSecret.
        /// </summary>
        /// <param name="cipherText">The text to decrypt.</param>
        /// <param name="sharedSecret">A password used to generate a key for decryption.</param>
        /// <param name="secret"></param>
        public static string DecryptStringAES(this string cipherText, string secret = null)
        {
            if (string.IsNullOrEmpty(cipherText))
                throw new ArgumentNullException("cipherText");
            if (string.IsNullOrEmpty(secret) && string.IsNullOrEmpty(AppSettings.EncryptionSecret))
                throw new ArgumentNullException("appSettings/EncryptionSecret");

            // Declare the RijndaelManaged object
            // used to decrypt the data.
            RijndaelManaged aesAlg = null;

            // Declare the string used to hold
            // the decrypted text.
            string plaintext = null;

            if (string.IsNullOrEmpty(secret))
                secret = AppSettings.EncryptionSecret;

            try
            {
                // generate the key from the shared secret and the salt
                Rfc2898DeriveBytes key = new Rfc2898DeriveBytes(secret, _salt);

                // Create the streams used for decryption.                
                byte[] bytes = Convert.FromBase64String(cipherText);
                using (MemoryStream msDecrypt = new MemoryStream(bytes))
                {
                    // Create a RijndaelManaged object
                    // with the specified key and IV.
                    aesAlg = new RijndaelManaged();
                    aesAlg.Key = key.GetBytes(aesAlg.KeySize / 8);
                    // Get the initialization vector from the encrypted stream
                    aesAlg.IV = ReadByteArray(msDecrypt);
                    // Create a decrytor to perform the stream transform.
                    ICryptoTransform decryptor = aesAlg.CreateDecryptor(aesAlg.Key, aesAlg.IV);
                    using (CryptoStream csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read))
                    {
                        using (StreamReader srDecrypt = new StreamReader(csDecrypt))
                        {
                            // Read the decrypted bytes from the decrypting stream
                            // and place them in a string.
                            plaintext = srDecrypt.ReadToEnd();
                        }
                    }
                }
            }
            finally
            {
                // Clear the RijndaelManaged object.
                if (aesAlg != null)
                    aesAlg.Clear();
            }

            return plaintext;
        }

        private static byte[] ReadByteArray(Stream s)
        {
            byte[] rawLength = new byte[sizeof(int)];
            if (s.Read(rawLength, 0, rawLength.Length) != rawLength.Length)
            {
                throw new SystemException("Stream did not contain properly formatted byte array");
            }

            byte[] buffer = new byte[BitConverter.ToInt32(rawLength, 0)];
            if (s.Read(buffer, 0, buffer.Length) != buffer.Length)
            {
                throw new SystemException("Did not read byte array properly");
            }

            return buffer;
        }

        public static string RemoveSpecialCharacters(this string str)
        {
            return Regex.Replace(str, "[^a-zA-Z0-9_. ]+", "", RegexOptions.Compiled);
        }
    }
}
