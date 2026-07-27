using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace GlassCraft
{
    public sealed class WindowCleaningGame : MonoBehaviour
    {
        private enum Tool { Inspect, Soak, Washer, Squeegee, Detail }

        private const int Columns = 20;
        private const int Rows = 12;
        private readonly List<Image> cells = new();
        private readonly float[] dirt = new float[Columns * Rows];
        private readonly float[] water = new float[Columns * Rows];
        private readonly Dictionary<Tool, Button> toolButtons = new();

        private RectTransform glass;
        private Text status;
        private Text scoreText;
        private Text instruction;
        private Tool selected = Tool.Inspect;
        private float startedAt;
        private float productUsed;
        private int wrongActions;
        private bool inspected;
        private bool finished;
        private int stage = 1;

        private readonly Color cleanGlass = new(0.52f, 0.75f, 0.82f, 0.46f);
        private readonly Color wetGlass = new(0.30f, 0.62f, 0.78f, 0.72f);
        private readonly Color dirtColor = new(0.24f, 0.18f, 0.10f, 0.90f);

        private void Awake()
        {
            BuildInterface();
            StartStage();
        }

        private void Update()
        {
            if (finished) return;

            Vector2 position;
            bool held;
            if (Input.touchCount > 0)
            {
                position = Input.GetTouch(0).position;
                held = Input.GetTouch(0).phase is TouchPhase.Began or TouchPhase.Moved or TouchPhase.Stationary;
            }
            else
            {
                position = Input.mousePosition;
                held = Input.GetMouseButton(0);
            }

            if (held && RectTransformUtility.ScreenPointToLocalPointInRectangle(glass, position, null, out var local))
            {
                var rect = glass.rect;
                var x = Mathf.FloorToInt((local.x - rect.xMin) / rect.width * Columns);
                var y = Mathf.FloorToInt((local.y - rect.yMin) / rect.height * Rows);
                ApplyTool(x, y);
            }
        }

        private void BuildInterface()
        {
            var canvasObject = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(2532, 1170);

            if (FindFirstObjectByType<EventSystem>() == null)
                new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var background = Panel(canvas.transform, "Workshop", new Color(0.055f, 0.075f, 0.09f, 1f),
                Vector2.zero, Vector2.one);

            var header = Panel(background, "Header", new Color(0.035f, 0.05f, 0.06f, 0.98f),
                new Vector2(0, 0.86f), Vector2.one);
            Label(header, "GLASS CRAFT", 42, TextAnchor.MiddleLeft,
                new Vector2(0.035f, 0), new Vector2(0.35f, 1), new Color(0.87f, 0.95f, 0.97f));
            scoreText = Label(header, "", 34, TextAnchor.MiddleRight,
                new Vector2(0.65f, 0), new Vector2(0.965f, 1), Color.white);

            var left = Panel(background, "ToolRack", new Color(0.075f, 0.10f, 0.115f, 1f),
                new Vector2(0.025f, 0.06f), new Vector2(0.22f, 0.83f));
            Label(left, "道具", 31, TextAnchor.MiddleCenter, new Vector2(0, 0.88f), Vector2.one, Color.white);

            AddToolButton(left, Tool.Inspect, "1  汚れを確認", 0.75f);
            AddToolButton(left, Tool.Soak, "2  予備洗浄", 0.60f);
            AddToolButton(left, Tool.Washer, "3  洗剤・ウォッシャー", 0.45f);
            AddToolButton(left, Tool.Squeegee, "4  スクイジー", 0.30f);
            AddToolButton(left, Tool.Detail, "5  端部を乾拭き", 0.15f);

            var frame = Panel(background, "WindowFrame", new Color(0.09f, 0.12f, 0.13f, 1f),
                new Vector2(0.245f, 0.13f), new Vector2(0.78f, 0.82f));
            glass = Panel(frame, "Glass", cleanGlass, new Vector2(0.025f, 0.035f), new Vector2(0.975f, 0.965f));
            var grid = glass.gameObject.AddComponent<GridLayoutGroup>();
            grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            grid.constraintCount = Columns;
            grid.spacing = new Vector2(1, 1);
            grid.cellSize = new Vector2(62, 62);
            grid.childAlignment = TextAnchor.MiddleCenter;

            for (var i = 0; i < Columns * Rows; i++)
            {
                var cell = new GameObject($"Pane_{i:000}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                cell.transform.SetParent(glass, false);
                var image = cell.GetComponent<Image>();
                image.raycastTarget = false;
                cells.Add(image);
            }

            var right = Panel(background, "JobCard", new Color(0.075f, 0.10f, 0.115f, 1f),
                new Vector2(0.80f, 0.13f), new Vector2(0.975f, 0.82f));
            Label(right, "作業票", 31, TextAnchor.MiddleCenter, new Vector2(0, 0.88f), Vector2.one, Color.white);
            instruction = Label(right, "", 27, TextAnchor.UpperLeft,
                new Vector2(0.08f, 0.35f), new Vector2(0.92f, 0.84f), new Color(0.82f, 0.89f, 0.91f));
            instruction.horizontalOverflow = HorizontalWrapMode.Wrap;
            instruction.verticalOverflow = VerticalWrapMode.Overflow;

            var judge = Button(right, "仕上がりを検査", new Vector2(0.08f, 0.08f), new Vector2(0.92f, 0.27f));
            judge.onClick.AddListener(Judge);

            status = Label(background, "", 29, TextAnchor.MiddleCenter,
                new Vector2(0.245f, 0.035f), new Vector2(0.78f, 0.115f), new Color(0.85f, 0.92f, 0.94f));
        }

        private void StartStage()
        {
            var random = new System.Random(8173 + stage * 97);
            for (var i = 0; i < dirt.Length; i++)
            {
                var edge = i % Columns < 2 || i % Columns > Columns - 3 || i / Columns < 2;
                dirt[i] = Mathf.Clamp01((float)random.NextDouble() * 0.65f + (edge ? 0.24f : 0.08f));
                water[i] = 0;
            }

            selected = Tool.Inspect;
            inspected = false;
            finished = false;
            productUsed = 0;
            wrongActions = 0;
            startedAt = Time.time;
            instruction.text = $"STAGE {stage:00}\n一般住宅・外窓\n\n目標\n・汚れ残り 3%未満\n・正しい工程\n・洗剤を使いすぎない";
            status.text = "まず光の反射を見て、汚れの種類と範囲を確認";
            RefreshAll();
            RefreshButtons();
        }

        private void ApplyTool(int x, int y)
        {
            if (x < 0 || x >= Columns || y < 0 || y >= Rows) return;
            var radius = selected == Tool.Squeegee ? 1 : 2;

            if (selected != Tool.Inspect && !inspected) wrongActions++;
            for (var oy = -radius; oy <= radius; oy++)
            for (var ox = -radius; ox <= radius; ox++)
            {
                var px = x + ox;
                var py = y + oy;
                if (px < 0 || px >= Columns || py < 0 || py >= Rows) continue;
                var index = py * Columns + px;
                var falloff = 1f - Mathf.Clamp01(new Vector2(ox, oy).magnitude / (radius + 0.5f));

                switch (selected)
                {
                    case Tool.Inspect:
                        inspected = true;
                        break;
                    case Tool.Soak:
                        water[index] = Mathf.Clamp01(water[index] + 0.09f * falloff);
                        productUsed += 0.001f;
                        break;
                    case Tool.Washer:
                        if (water[index] > 0.12f) dirt[index] = Mathf.Max(0, dirt[index] - 0.07f * falloff);
                        else wrongActions++;
                        water[index] = Mathf.Clamp01(water[index] + 0.045f);
                        productUsed += 0.002f;
                        break;
                    case Tool.Squeegee:
                        if (water[index] > 0.08f)
                        {
                            dirt[index] = Mathf.Max(0, dirt[index] - 0.14f * falloff);
                            water[index] = Mathf.Max(0, water[index] - 0.16f);
                        }
                        else wrongActions++;
                        break;
                    case Tool.Detail:
                        var edge = px == 0 || px == Columns - 1 || py == 0 || py == Rows - 1;
                        if (edge)
                        {
                            dirt[index] = Mathf.Max(0, dirt[index] - 0.07f * falloff);
                            water[index] = Mathf.Max(0, water[index] - 0.18f);
                        }
                        else if (water[index] > 0.02f) water[index] *= 0.96f;
                        break;
                }
                RefreshCell(index);
            }

            status.text = selected switch
            {
                Tool.Inspect => "汚れを確認しました。上から下へ予備洗浄",
                Tool.Soak => "砂や埃を水で流し、傷を防ぐ",
                Tool.Washer => "洗剤を均一に広げて汚れを浮かせる",
                Tool.Squeegee => "ゴムを寝かせすぎず、上から水を切る",
                _ => "四辺の水分をクロスで回収"
            };
        }

        private void SelectTool(Tool tool)
        {
            selected = tool;
            RefreshButtons();
        }

        private void Judge()
        {
            var remaining = 0f;
            var moisture = 0f;
            for (var i = 0; i < dirt.Length; i++)
            {
                remaining += dirt[i];
                moisture += water[i];
            }
            remaining /= dirt.Length;
            moisture /= water.Length;
            var elapsed = Time.time - startedAt;
            var cleanliness = Mathf.Clamp01(1f - remaining * 3.2f);
            var dryness = Mathf.Clamp01(1f - moisture * 2.5f);
            var efficiency = Mathf.Clamp01(1f - Mathf.Max(0, productUsed - 1.35f) * 0.12f);
            var procedure = Mathf.Clamp01(1f - wrongActions / 180f);
            var speed = Mathf.Clamp01(1f - Mathf.Max(0, elapsed - 150f) / 240f);
            var score = Mathf.RoundToInt((cleanliness * 0.50f + dryness * 0.16f + procedure * 0.18f +
                                          efficiency * 0.10f + speed * 0.06f) * 10000);

            scoreText.text = $"SCORE  {score:N0}";
            if (remaining <= 0.03f && moisture <= 0.025f && score >= 7200)
            {
                finished = true;
                status.text = $"合格　汚れ残り {remaining * 100:0.0}%　タップで次の現場へ";
                var next = Button(status.transform.parent, "次の現場", new Vector2(0.62f, 0.035f), new Vector2(0.78f, 0.115f));
                next.onClick.AddListener(() =>
                {
                    Destroy(next.gameObject);
                    stage++;
                    StartStage();
                });
            }
            else
            {
                status.text = $"再清掃　汚れ {remaining * 100:0.0}% / 水分 {moisture * 100:0.0}%　光を変えて確認";
            }
        }

        private void RefreshAll()
        {
            for (var i = 0; i < cells.Count; i++) RefreshCell(i);
            scoreText.text = "SCORE  —";
        }

        private void RefreshCell(int i)
        {
            var baseColor = Color.Lerp(cleanGlass, wetGlass, water[i]);
            cells[i].color = Color.Lerp(baseColor, dirtColor, Mathf.Clamp01(dirt[i]));
        }

        private void RefreshButtons()
        {
            foreach (var item in toolButtons)
            {
                var colors = item.Value.colors;
                colors.normalColor = item.Key == selected
                    ? new Color(0.12f, 0.55f, 0.63f)
                    : new Color(0.12f, 0.16f, 0.18f);
                item.Value.colors = colors;
            }
        }

        private void AddToolButton(Transform parent, Tool tool, string title, float y)
        {
            var button = Button(parent, title, new Vector2(0.07f, y), new Vector2(0.93f, y + 0.115f));
            button.onClick.AddListener(() => SelectTool(tool));
            toolButtons.Add(tool, button);
        }

        private static RectTransform Panel(Transform parent, string name, Color color, Vector2 min, Vector2 max)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            go.GetComponent<Image>().color = color;
            return rect;
        }

        private static Text Label(Transform parent, string value, int size, TextAnchor anchor,
            Vector2 min, Vector2 max, Color color)
        {
            var go = new GameObject("Label", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            var text = go.GetComponent<Text>();
            text.text = value;
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = size;
            text.alignment = anchor;
            text.color = color;
            text.raycastTarget = false;
            return text;
        }

        private static Button Button(Transform parent, string title, Vector2 min, Vector2 max)
        {
            var panel = Panel(parent, title, new Color(0.12f, 0.16f, 0.18f), min, max);
            var button = panel.gameObject.AddComponent<Button>();
            var colors = button.colors;
            colors.highlightedColor = new Color(0.16f, 0.60f, 0.68f);
            colors.pressedColor = new Color(0.08f, 0.42f, 0.50f);
            button.colors = colors;
            Label(panel, title, 24, TextAnchor.MiddleCenter, Vector2.zero, Vector2.one, Color.white);
            return button;
        }
    }
}
