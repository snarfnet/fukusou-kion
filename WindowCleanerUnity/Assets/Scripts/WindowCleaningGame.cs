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
        private RectTransform handRig;
        private RectTransform toolHandle;
        private RectTransform toolHead;
        private CanvasGroup handCanvas;
        private Vector2 handTarget;
        private Vector2 handVelocity;
        private float handActivity;
        private Tool selected = Tool.Inspect;
        private float startedAt;
        private float productUsed;
        private int wrongActions;
        private bool inspected;
        private bool finished;
        private int stage = 1;

        private readonly Color cleanGlass = new(0.32f, 0.52f, 0.60f, 0.30f);
        private readonly Color wetGlass = new(0.18f, 0.50f, 0.65f, 0.58f);
        private readonly Color dirtColor = new(0.22f, 0.15f, 0.08f, 0.88f);

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
                MoveHand(position);
            }

            AnimateHand();
        }

        private void BuildInterface()
        {
            var canvasObject = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;

            if (FindFirstObjectByType<EventSystem>() == null)
                new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var background = Panel(canvas.transform, "StreetAtDusk", new Color(0.055f, 0.065f, 0.075f, 1f),
                Vector2.zero, Vector2.one);
            CreateFacade(background);

            var header = Panel(background, "Header", new Color(0.025f, 0.035f, 0.04f, 0.98f),
                new Vector2(0, 0.875f), Vector2.one);
            Label(header, "GLASS CRAFT", 52, FontStyle.Bold, TextAnchor.MiddleLeft,
                new Vector2(0.035f, 0), new Vector2(0.42f, 1), new Color(0.90f, 0.97f, 0.98f));
            Label(header, "PRO WINDOW SERVICE", 25, FontStyle.Normal, TextAnchor.MiddleLeft,
                new Vector2(0.285f, 0), new Vector2(0.56f, 1), new Color(0.48f, 0.72f, 0.76f));
            scoreText = Label(header, "", 42, FontStyle.Bold, TextAnchor.MiddleRight,
                new Vector2(0.66f, 0), new Vector2(0.965f, 1), Color.white);

            var left = Panel(background, "ToolRack", new Color(0.045f, 0.06f, 0.067f, 0.98f),
                new Vector2(0.018f, 0.055f), new Vector2(0.235f, 0.845f));
            Label(left, "清掃ツール", 38, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0, 0.88f), Vector2.one, Color.white);
            AddToolButton(left, Tool.Inspect, "1  汚れを確認", 0.73f);
            AddToolButton(left, Tool.Soak, "2  予備洗浄", 0.575f);
            AddToolButton(left, Tool.Washer, "3  ウォッシャー", 0.42f);
            AddToolButton(left, Tool.Squeegee, "4  スクイジー", 0.265f);
            AddToolButton(left, Tool.Detail, "5  端部を仕上げ", 0.11f);

            var store = Panel(background, "Storefront", new Color(0.16f, 0.15f, 0.135f, 1f),
                new Vector2(0.25f, 0.11f), new Vector2(0.79f, 0.845f));
            Label(store, "AOYAMA  FLAGSHIP  STORE", 28, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0.08f, 0.91f), new Vector2(0.92f, 0.985f), new Color(0.93f, 0.88f, 0.72f));
            var frame = Panel(store, "AluminiumFrame", new Color(0.045f, 0.052f, 0.055f, 1f),
                new Vector2(0.028f, 0.035f), new Vector2(0.972f, 0.90f));
            BuildStoreWindow(frame);

            var right = Panel(background, "JobCard", new Color(0.045f, 0.06f, 0.067f, 0.98f),
                new Vector2(0.805f, 0.11f), new Vector2(0.982f, 0.845f));
            Label(right, "作業指示", 38, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0, 0.87f), Vector2.one, Color.white);
            instruction = Label(right, "", 31, FontStyle.Normal, TextAnchor.UpperLeft,
                new Vector2(0.08f, 0.34f), new Vector2(0.92f, 0.84f), new Color(0.88f, 0.93f, 0.94f));
            instruction.horizontalOverflow = HorizontalWrapMode.Wrap;
            instruction.verticalOverflow = VerticalWrapMode.Overflow;

            var judge = Button(right, "仕上がりを検査", new Vector2(0.07f, 0.07f), new Vector2(0.93f, 0.26f));
            judge.onClick.AddListener(Judge);

            status = Label(background, "", 31, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0.25f, 0.025f), new Vector2(0.79f, 0.095f), new Color(0.92f, 0.96f, 0.97f));
        }

        private void CreateFacade(Transform parent)
        {
            Panel(parent, "ConcreteWall", new Color(0.18f, 0.17f, 0.155f, 1f),
                new Vector2(0.235f, 0.095f), new Vector2(0.805f, 0.875f));
            Panel(parent, "Pavement", new Color(0.08f, 0.085f, 0.09f, 1f),
                new Vector2(0, 0), new Vector2(1, 0.055f));
            Panel(parent, "WarmWallLightLeft", new Color(0.75f, 0.52f, 0.25f, 0.18f),
                new Vector2(0.237f, 0.68f), new Vector2(0.25f, 0.82f));
            Panel(parent, "WarmWallLightRight", new Color(0.75f, 0.52f, 0.25f, 0.18f),
                new Vector2(0.79f, 0.68f), new Vector2(0.803f, 0.82f));
        }

        private void BuildStoreWindow(RectTransform frame)
        {
            var interior = Panel(frame, "StoreInterior", new Color(0.10f, 0.09f, 0.075f, 1f),
                new Vector2(0.018f, 0.022f), new Vector2(0.982f, 0.978f));
            Panel(interior, "CeilingGlow", new Color(0.95f, 0.78f, 0.48f, 0.50f),
                new Vector2(0, 0.82f), new Vector2(1, 1));
            Panel(interior, "BackWall", new Color(0.37f, 0.30f, 0.22f, 1f),
                new Vector2(0.06f, 0.12f), new Vector2(0.94f, 0.82f));
            Panel(interior, "DisplayShelf1", new Color(0.09f, 0.07f, 0.055f, 1f),
                new Vector2(0.10f, 0.31f), new Vector2(0.90f, 0.35f));
            Panel(interior, "DisplayShelf2", new Color(0.09f, 0.07f, 0.055f, 1f),
                new Vector2(0.10f, 0.54f), new Vector2(0.90f, 0.58f));
            for (var i = 0; i < 7; i++)
            {
                var x = 0.12f + i * 0.115f;
                Panel(interior, $"Product_{i}", new Color(0.65f - i * 0.035f, 0.52f, 0.34f, 1f),
                    new Vector2(x, 0.35f), new Vector2(x + 0.055f, 0.51f));
            }
            Panel(interior, "Counter", new Color(0.12f, 0.09f, 0.07f, 1f),
                new Vector2(0.57f, 0.10f), new Vector2(0.94f, 0.27f));
            Panel(interior, "PersonSilhouette", new Color(0.035f, 0.038f, 0.04f, 0.82f),
                new Vector2(0.43f, 0.10f), new Vector2(0.50f, 0.48f));

            glass = Panel(frame, "GlassSurface", cleanGlass,
                new Vector2(0.018f, 0.022f), new Vector2(0.982f, 0.978f));
            var grid = glass.gameObject.AddComponent<GridLayoutGroup>();
            grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            grid.constraintCount = Columns;
            grid.spacing = Vector2.zero;
            grid.childAlignment = TextAnchor.MiddleCenter;
            grid.cellSize = new Vector2(49, 55);

            for (var i = 0; i < Columns * Rows; i++)
            {
                var cell = new GameObject($"Pane_{i:000}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                cell.transform.SetParent(glass, false);
                var image = cell.GetComponent<Image>();
                image.raycastTarget = false;
                cells.Add(image);
            }

            Panel(frame, "SkyReflection", new Color(0.52f, 0.71f, 0.78f, 0.10f),
                new Vector2(0.04f, 0.62f), new Vector2(0.96f, 0.91f));
            Panel(frame, "ReflectionStreak", new Color(0.90f, 0.96f, 1f, 0.12f),
                new Vector2(0.16f, 0.05f), new Vector2(0.21f, 0.94f));
            Panel(frame, "ReflectionStreak2", new Color(0.90f, 0.96f, 1f, 0.07f),
                new Vector2(0.72f, 0.04f), new Vector2(0.76f, 0.95f));
            Panel(frame, "CenterMullion", new Color(0.055f, 0.065f, 0.068f, 1f),
                new Vector2(0.488f, 0), new Vector2(0.512f, 1));
            Panel(frame, "Transom", new Color(0.055f, 0.065f, 0.068f, 1f),
                new Vector2(0, 0.68f), new Vector2(1, 0.705f));
            Panel(frame, "BottomSeal", new Color(0.025f, 0.03f, 0.032f, 1f),
                new Vector2(0, 0), new Vector2(1, 0.025f));
            BuildAnimatedHand(frame);
        }

        private void BuildAnimatedHand(RectTransform frame)
        {
            handRig = Panel(frame, "CleanerHand", Color.clear, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));
            handRig.sizeDelta = new Vector2(230, 310);
            handRig.anchoredPosition = new Vector2(150, -250);
            handCanvas = handRig.gameObject.AddComponent<CanvasGroup>();
            handCanvas.alpha = 0.88f;

            var sleeve = Panel(handRig, "Sleeve", new Color(0.06f, 0.10f, 0.12f, 1f),
                new Vector2(0.33f, -0.18f), new Vector2(0.82f, 0.34f));
            sleeve.localRotation = Quaternion.Euler(0, 0, -12);
            var cuff = Panel(handRig, "GloveCuff", new Color(0.08f, 0.42f, 0.52f, 1f),
                new Vector2(0.29f, 0.18f), new Vector2(0.78f, 0.36f));
            cuff.localRotation = Quaternion.Euler(0, 0, -10);
            var palm = Panel(handRig, "GlovedPalm", new Color(0.10f, 0.57f, 0.66f, 1f),
                new Vector2(0.25f, 0.30f), new Vector2(0.76f, 0.65f));
            palm.localRotation = Quaternion.Euler(0, 0, -8);
            for (var i = 0; i < 4; i++)
            {
                var finger = Panel(handRig, $"Finger_{i}", new Color(0.12f, 0.62f, 0.70f, 1f),
                    new Vector2(0.27f + i * 0.105f, 0.58f), new Vector2(0.36f + i * 0.105f, 0.82f));
                finger.localRotation = Quaternion.Euler(0, 0, -8 + i * 2);
            }
            var thumb = Panel(handRig, "Thumb", new Color(0.11f, 0.59f, 0.68f, 1f),
                new Vector2(0.12f, 0.38f), new Vector2(0.39f, 0.53f));
            thumb.localRotation = Quaternion.Euler(0, 0, 25);

            toolHandle = Panel(handRig, "ToolHandle", new Color(0.08f, 0.09f, 0.095f, 1f),
                new Vector2(0.48f, 0.53f), new Vector2(0.58f, 1.20f));
            toolHandle.localRotation = Quaternion.Euler(0, 0, 4);
            toolHead = Panel(handRig, "ToolHead", new Color(0.04f, 0.05f, 0.055f, 1f),
                new Vector2(0.15f, 1.10f), new Vector2(0.91f, 1.22f));
            UpdateHeldTool();
        }

        private void MoveHand(Vector2 screenPosition)
        {
            if (handRig == null) return;
            var frame = handRig.parent as RectTransform;
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(frame, screenPosition, null, out var local))
            {
                handTarget = local + new Vector2(92, -135);
                handActivity = 1f;
            }
        }

        private void AnimateHand()
        {
            if (handRig == null) return;
            handActivity = Mathf.MoveTowards(handActivity, 0.35f, Time.deltaTime * 0.45f);
            handRig.anchoredPosition = Vector2.SmoothDamp(
                handRig.anchoredPosition, handTarget, ref handVelocity, 0.075f);
            var speedTilt = Mathf.Clamp(-handVelocity.x * 0.018f, -11f, 11f);
            var workingMotion = Mathf.Sin(Time.time * 8f) * 2.2f * handActivity;
            handRig.localRotation = Quaternion.Euler(0, 0, speedTilt + workingMotion);
            handCanvas.alpha = Mathf.MoveTowards(handCanvas.alpha, 0.94f, Time.deltaTime * 2f);
        }

        private void UpdateHeldTool()
        {
            if (toolHead == null || toolHandle == null) return;
            var headImage = toolHead.GetComponent<Image>();
            var handleImage = toolHandle.GetComponent<Image>();
            toolHead.gameObject.SetActive(selected != Tool.Inspect);
            toolHandle.gameObject.SetActive(selected != Tool.Inspect && selected != Tool.Detail);

            switch (selected)
            {
                case Tool.Soak:
                    toolHead.anchorMin = new Vector2(0.25f, 1.08f);
                    toolHead.anchorMax = new Vector2(0.82f, 1.28f);
                    headImage.color = new Color(0.22f, 0.55f, 0.72f, 0.90f);
                    break;
                case Tool.Washer:
                    toolHead.anchorMin = new Vector2(0.13f, 1.08f);
                    toolHead.anchorMax = new Vector2(0.93f, 1.26f);
                    headImage.color = new Color(0.82f, 0.72f, 0.36f, 1f);
                    handleImage.color = new Color(0.12f, 0.13f, 0.14f, 1f);
                    break;
                case Tool.Squeegee:
                    toolHead.anchorMin = new Vector2(0.08f, 1.12f);
                    toolHead.anchorMax = new Vector2(0.98f, 1.21f);
                    headImage.color = new Color(0.025f, 0.03f, 0.032f, 1f);
                    handleImage.color = new Color(0.16f, 0.17f, 0.18f, 1f);
                    break;
                case Tool.Detail:
                    toolHead.anchorMin = new Vector2(0.27f, 0.82f);
                    toolHead.anchorMax = new Vector2(0.80f, 1.14f);
                    headImage.color = new Color(0.84f, 0.88f, 0.88f, 0.92f);
                    break;
            }
            toolHead.offsetMin = Vector2.zero;
            toolHead.offsetMax = Vector2.zero;
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
            instruction.text = $"STAGE {stage:00}\n店舗・大型ガラス\n\n目標\n・汚れ残り 3%未満\n・正しい作業手順\n・洗剤を使いすぎない";
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
                Tool.Soak => "砂や泥を水で流し、ガラスを十分に濡らす",
                Tool.Washer => "洗剤を均一に広げて、汚れを浮かせる",
                Tool.Squeegee => "ゴムを寝かせすぎず、上から水を切る",
                _ => "四辺に残った水分をクロスで回収"
            };
        }

        private void SelectTool(Tool tool)
        {
            selected = tool;
            RefreshButtons();
            UpdateHeldTool();
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
                status.text = $"合格　汚れ残り {remaining * 100:0.0}%　次の現場へ";
                var next = Button(status.transform.parent, "次の現場", new Vector2(0.64f, 0.025f), new Vector2(0.79f, 0.095f));
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
                    ? new Color(0.08f, 0.55f, 0.62f)
                    : new Color(0.10f, 0.13f, 0.14f);
                item.Value.colors = colors;
            }
        }

        private void AddToolButton(Transform parent, Tool tool, string title, float y)
        {
            var button = Button(parent, title, new Vector2(0.055f, y), new Vector2(0.945f, y + 0.125f));
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
            var image = go.GetComponent<Image>();
            image.color = color;
            image.raycastTarget = false;
            return rect;
        }

        private static Text Label(Transform parent, string value, int size, FontStyle style, TextAnchor anchor,
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
            text.fontStyle = style;
            text.alignment = anchor;
            text.color = color;
            text.raycastTarget = false;
            return text;
        }

        private static Button Button(Transform parent, string title, Vector2 min, Vector2 max)
        {
            var panel = Panel(parent, title, new Color(0.10f, 0.13f, 0.14f), min, max);
            panel.GetComponent<Image>().raycastTarget = true;
            var button = panel.gameObject.AddComponent<Button>();
            var colors = button.colors;
            colors.highlightedColor = new Color(0.12f, 0.60f, 0.68f);
            colors.pressedColor = new Color(0.06f, 0.40f, 0.47f);
            button.colors = colors;
            Label(panel, title, 32, FontStyle.Bold, TextAnchor.MiddleCenter, Vector2.zero, Vector2.one, Color.white);
            return button;
        }
    }
}
