<h4>資料前處理（清理）:</h4>
- 移除沒有 scientificName 的資料 (476,522 筆)<br>
- 移除重複資料 (768 筆)<br>
- 移除沒有經緯度坐標的資料 (864,912 筆)<br>
- 移除經緯度坐標不在台灣海陸疆界内的資料 (136,368 筆)<br>
<br>


<h3>檢視不同頁面時的注意事項：</h3>

#### 1. 物種上的資料概況<br>
- 我們把物種大致分成了 33 個大類群以方便呈現。分群方式請看此[表單](https://docs.google.com/spreadsheets/d/1kDXFF94Nkabfzhhj3rZLlEwnAeM8WBSrhqPiCPKggH8/edit?usp=sharing)。<br>
- 我們比照[臺灣物種名錄](https://taicol.tw/)（以下簡稱：TaiCOL），將 TBIA 入口網還未曾紀錄過的物種表單輸出成 CSV 供下載。<br>

#### 2. 時間上的資料概況<br>
- 我們沒有移除時間有疑慮的資料（例如：年份 < 1800 & > 2025），因為這些資料佔了不到 200 筆。<br>

#### 3 & 4. 空間上的資料概況與空缺<br>
- 敏感資料在座標上有著不同程度的模糊化。為了利於後續資料空缺概況的分析與呈現，我們將資料的座標欄位進行合併。在敏感資料上，我們使用該原始座標點位 standardRawLatitude 和 standardRawLongitude，與非敏感資料的 standardLatitude 和 standardLongitude 進行合併，生成 latitude 和 longitude 欄位給後續分析並做呈現。
- 我們使用 EPSG:4326 WGS84 大地坐標系統，將資料呈現在 5x5 公里網格的台灣海陸疆界内。<br> 
- 在將資料套曡在網格上時，我們排除了座標模糊化大於5公里的資料（1,183,339 筆）。
