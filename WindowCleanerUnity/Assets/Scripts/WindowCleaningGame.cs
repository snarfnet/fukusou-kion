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
        private enum DirtKind { Mud, Oil, Stuck }

        private const int Columns = 20;
        private const int Rows = 12;
        private readonly List<Image> cells = new();
        private readonly float[] dirt = new float[Columns * Rows];
        private readonly float[] water = new float[Columns * Rows];
        private readonly float[] streak = new float[Columns * Rows];
        private readonly float[] agitation = new float[Columns * Rows];
        private readonly DirtKind[] dirtKinds = new DirtKind[Columns * Rows];
        private readonly Dictionary<Tool, Button> toolButtons = new();

        private RectTransform glass;
        private RectTransform handRig;
        private Image handImage;
        private CanvasGroup handCanvas;
        private Text status;
        private Text scoreText;
        private Text instruction;
        private Text timerText;
        private Vector2 handTarget;
        private Vector2 handVelocity;
        private Vector2 previousGlassPoint;
        private Vector2 cleaningDirection;
        private float handActivity;
        private float remainingTime;
        private float startedAt;
        private float productUsed;
        private int wrongActions;
        private bool hasPreviousGlassPoint;
        private bool inspectionLight;
        private bool inspected;
        private bool finished;
        private Tool selected = Tool.Inspect;
        private int stage = 1;

        private void Awake()
        {
            BuildInterface();
            StartStage();
        }

        private void Update()
        {
            if (finished) return;

            remainingTime = Mathf.Max(0, remainingTime - Time.deltaTime);
            UpdateTimer();
            if (remainingTime <= 0)
            {
                finished = true;
                status.text = "時間切れ。開店に間に合いませんでした。もう一度挑戦してください。";
                return;
            }

            Vector2 position;
            bool held;
            if (Input.touchCount > 0)
            {
                var touch = Input.GetTouch(0);
                position = touch.position;
                held = touch.phase is TouchPhase.Began or TouchPhase.Moved or TouchPhase.Stationary;
            }
            else
            {
                position = Input.mousePosition;
                held = Input.GetMouseButton(0);
            }

            if (held && RectTransformUtility.ScreenPointToLocalPointInRectangle(glass, position, null, out var local)
                     && glass.rect.Contains(local))
            {
                cleaningDirection = hasPreviousGlassPoint ? local - previousGlassPoint : Vector2.up;
                previousGlassPoint = local;
                hasPreviousGlassPoint = true;
                var rect = glass.rect;
                var x = Mathf.FloorToInt((local.x - rect.xMin) / rect.width * Columns);
                var y = Mathf.FloorToInt((local.y - rect.yMin) / rect.height * Rows);
                ApplyTool(x, y);
                MoveHand(position);
            }
            else
            {
                hasPreviousGlassPoint = false;
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

            var background = Panel(canvas.transform, "Background", new Color(0.045f, 0.052f, 0.058f), Vector2.zero, Vector2.one);
            var header = Panel(background, "Header", new Color(0.018f, 0.026f, 0.03f, 0.97f), new Vector2(0, 0.875f), Vector2.one);
            Label(header, "GLASS CRAFT", 48, FontStyle.Bold, TextAnchor.MiddleLeft,
                new Vector2(0.03f, 0), new Vector2(0.34f, 1), new Color(0.88f, 0.97f, 0.98f));
            timerText = Label(header, "", 40, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0.38f, 0), new Vector2(0.66f, 1), Color.white);
            scoreText = Label(header, "", 40, FontStyle.Bold, TextAnchor.MiddleRight,
                new Vector2(0.67f, 0), new Vector2(0.97f, 1), Color.white);

            var left = Panel(background, "ToolRack", new Color(0.035f, 0.052f, 0.06f, 0.98f),
                new Vector2(0.015f, 0.055f), new Vector2(0.235f, 0.85f));
            Label(left, "清掃ツール", 38, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0, 0.88f), Vector2.one, Color.white);
            AddToolButton(left, Tool.Inspect, "1　汚れを検査", 0.73f);
            AddToolButton(left, Tool.Soak, "2　予備洗浄", 0.575f);
            AddToolButton(left, Tool.Washer, "3　ウォッシャー", 0.42f);
            AddToolButton(left, Tool.Squeegee, "4　スクイジー", 0.265f);
            AddToolButton(left, Tool.Detail, "5　クロス仕上げ", 0.11f);

            var store = PhotoPanel(background, "CafeStorefront", "Art/CafeStorefront",
                new Vector2(0.245f, 0.105f), new Vector2(0.795f, 0.85f));
            var frame = Panel(store, "InteractiveWindow", Color.clear, Vector2.zero, Vector2.one);
            BuildStoreWindow(frame);

            var right = Panel(background, "JobCard", new Color(0.035f, 0.052f, 0.06f, 0.98f),
                new Vector2(0.805f, 0.105f), new Vector2(0.985f, 0.85f));
            Label(right, "本日の現場", 38, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0, 0.87f), Vector2.one, Color.white);
            instruction = Label(right, "", 29, FontStyle.Normal, TextAnchor.UpperLeft,
                new Vector2(0.07f, 0.31f), new Vector2(0.93f, 0.84f), new Color(0.9f, 0.94f, 0.95f));
            instruction.horizontalOverflow = HorizontalWrapMode.Wrap;
            instruction.verticalOverflow = VerticalWrapMode.Overflow;

            var judge = Button(right, "仕上がりを検査", new Vector2(0.07f, 0.07f), new Vector2(0.93f, 0.25f));
            judge.onClick.AddListener(Judge);
            status = Label(background, "", 30, FontStyle.Bold, TextAnchor.MiddleCenter,
                new Vector2(0.245f, 0.018f), new Vector2(0.795f, 0.095f), new Color(0.93f, 0.97f, 0.98f));
        }

        private void BuildStoreWindow(RectTransform frame)
        {
            glass = Panel(frame, "GlassSurface", new Color(0.18f, 0.32f, 0.38f, 0.06f),
                new Vector2(0.115f, 0.16f), new Vector2(0.91f, 0.845f));
            var grid = glass.gameObject.AddComponent<GridLayoutGroup>();
            grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            grid.constraintCount = Columns;
            grid.spacing = Vector2.zero;
            grid.childAlignment = TextAnchor.MiddleCenter;
            grid.cellSize = new Vector2(41, 43);

            for (var i = 0; i < Columns * Rows; i++)
            {
                var cell = new GameObject($"Dirt_{i:000}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                cell.transform.SetParent(glass, false);
                var image = cell.GetComponent<Image>();
                image.raycastTarget = false;
                cells.Add(image);
            }

            Panel(frame, "TopReflection", new Color(0.76f, 0.89f, 0.94f, 0.06f),
                new Vector2(0.12f, 0.69f), new Vector2(0.91f, 0.84f));
            BuildAnimatedHand(frame);
        }

        private void BuildAnimatedHand(RectTransform frame)
        {
            handRig = Panel(frame, "CleanerHand", Color.clear, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f));
            handRig.sizeDelta = new Vector2(620, 620);
            handRig.anchoredPosition = new Vector2(190, -250);
            handCanvas = handRig.gameObject.AddComponent<CanvasGroup>();
            handCanvas.alpha = 0.96f;
            handImage = ImageElement(handRig, "PhotorealHand", Vector2.zero, Vector2.one);
            handImage.preserveAspect = true;
            UpdateHeldTool();
        }

        private void MoveHand(Vector2 screenPosition)
        {
            if (handRig == null) return;
            var frame = handRig.parent as RectTransform;
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(frame, screenPosition, null, out var local))
            {
                handTarget = local + new Vector2(165, -205);
                handActivity = 1f;
            }
        }

        private void AnimateHand()
        {
            if (handRig == null) return;
            handActivity = Mathf.MoveTowards(handActivity, 0.25f, Time.deltaTime * 0.55f);
            handRig.anchoredPosition = Vector2.SmoothDamp(handRig.anchoredPosition, handTarget, ref handVelocity, 0.07f);
            var directionTilt = Mathf.Clamp(-cleaningDirection.x * 0.16f, -10f, 10f);
            var workingMotion = Mathf.Sin(Time.time * 8f) * 1.8f * handActivity;
            handRig.localRotation = Quaternion.Euler(0, 0, directionTilt + workingMotion);
        }

        private void UpdateHeldTool()
        {
            if (handImage == null) return;
            handImage.gameObject.SetActive(selected != Tool.Inspect);
            var path = selected switch
            {
                Tool.Squeegee => "Art/SqueegeeHand",
                Tool.Detail => "Art/ClothHand",
                _ => "Art/WasherHand"
            };
            handImage.sprite = LoadSprite(path);
        }

        private void StartStage()
        {
            var random = new System.Random(8173 + stage * 97);
            for (var i = 0; i < dirt.Length; i++)
            {
                var x = i % Columns;
                var y = i / Columns;
                var edge = x < 2 || x > Columns - 3 || y < 2;
                dirt[i] = Mathf.Clamp01((float)random.NextDouble() * 0.58f + (edge ? 0.30f : 0.12f));
                water[i] = 0;
                streak[i] = 0;
                agitation[i] = 0;
                var typeRoll = (x / 4 + y / 3 + stage) % 10;
                dirtKinds[i] = typeRoll < 5 ? DirtKind.Mud : typeRoll < 8 ? DirtKind.Oil : DirtKind.Stuck;
            }

            selected = Tool.Inspect;
            inspected = false;
            inspectionLight = false;
            finished = false;
            productUsed = 0;
            wrongActions = 0;
            remainingTime = Mathf.Max(105f, 180f - (stage - 1) * 10f);
            startedAt = Time.time;
            instruction.text = $"STAGE {stage:00}\n開店前のカフェ\n\n泥汚れ：水でゆるめる\n油膜：よく擦る\n固着汚れ：クロス仕上げ\n\n縦にスクイジーを動かすと\n水筋を残しにくい";
            status.text = "まず検査灯で、汚れの種類と範囲を確認してください。";
            handTarget = new Vector2(190, -250);
            RefreshAll();
            RefreshButtons();
            UpdateHeldTool();
            UpdateTimer();
        }

        private void ApplyTool(int x, int y)
        {
            if (x < 0 || x >= Columns || y < 0 || y >= Rows) return;
            var radius = selected == Tool.Squeegee ? 1 : 2;
            if (selected != Tool.Inspect && !inspected) wrongActions++;

            var movement = Mathf.Abs(cleaningDirection.x) + Mathf.Abs(cleaningDirection.y);
            var verticalTechnique = movement < 1f ? 1f : Mathf.Clamp01(Mathf.Abs(cleaningDirection.y) / movement);

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
                        inspectionLight = true;
                        break;
                    case Tool.Soak:
                        water[index] = Mathf.Clamp01(water[index] + 0.085f * falloff);
                        if (dirtKinds[index] == DirtKind.Mud)
                            dirt[index] = Mathf.Max(0, dirt[index] - 0.025f * falloff);
                        productUsed += 0.001f;
                        break;
                    case Tool.Washer:
                        if (water[index] <= 0.1f)
                        {
                            wrongActions++;
                            streak[index] = Mathf.Clamp01(streak[index] + 0.015f);
                        }
                        else
                        {
                            agitation[index] = Mathf.Clamp01(agitation[index] + 0.075f * falloff);
                            var strength = dirtKinds[index] switch
                            {
                                DirtKind.Mud => 0.085f,
                                DirtKind.Oil => agitation[index] > 0.3f ? 0.095f : 0.035f,
                                _ => 0.025f
                            };
                            dirt[index] = Mathf.Max(0, dirt[index] - strength * falloff);
                        }
                        water[index] = Mathf.Clamp01(water[index] + 0.035f);
                        productUsed += 0.002f;
                        break;
                    case Tool.Squeegee:
                        if (water[index] > 0.055f)
                        {
                            dirt[index] = Mathf.Max(0, dirt[index] - 0.075f * falloff * (0.55f + verticalTechnique * 0.45f));
                            water[index] = Mathf.Max(0, water[index] - 0.17f * falloff);
                            streak[index] = verticalTechnique < 0.55f
                                ? Mathf.Clamp01(streak[index] + 0.12f * (1f - verticalTechnique))
                                : Mathf.Max(0, streak[index] - 0.065f);
                        }
                        else wrongActions++;
                        break;
                    case Tool.Detail:
                        var edge = px == 0 || px == Columns - 1 || py == 0 || py == Rows - 1;
                        var stuckReady = dirtKinds[index] == DirtKind.Stuck && agitation[index] > 0.12f;
                        if (edge || stuckReady)
                            dirt[index] = Mathf.Max(0, dirt[index] - 0.085f * falloff);
                        else if (dirt[index] > 0.04f)
                            wrongActions++;
                        water[index] = Mathf.Max(0, water[index] - 0.13f * falloff);
                        streak[index] = Mathf.Max(0, streak[index] - 0.15f * falloff);
                        break;
                }
                RefreshCell(index);
            }

            status.text = selected switch
            {
                Tool.Inspect => DirtSummary(),
                Tool.Soak => "予備洗浄中。泥汚れを水で十分にゆるめます。",
                Tool.Washer => "ウォッシャーで洗浄中。油膜は往復してよく擦ります。",
                Tool.Squeegee when verticalTechnique >= 0.55f => "良い角度です。上から下へ水を切っています。",
                Tool.Squeegee => "横滑りしています。縦方向へ動かすと水筋を防げます。",
                _ => "クロスで四辺・固着汚れ・水筋を仕上げています。"
            };
        }

        private string DirtSummary()
        {
            var mud = 0;
            var oil = 0;
            var stuck = 0;
            for (var i = 0; i < dirt.Length; i++)
            {
                if (dirt[i] < 0.08f) continue;
                if (dirtKinds[i] == DirtKind.Mud) mud++;
                else if (dirtKinds[i] == DirtKind.Oil) oil++;
                else stuck++;
            }
            return $"検査灯 ON　泥 {mud} / 油膜 {oil} / 固着 {stuck}";
        }

        private void SelectTool(Tool tool)
        {
            selected = tool;
            inspectionLight = tool == Tool.Inspect && inspected;
            RefreshButtons();
            RefreshAll();
            UpdateHeldTool();
        }

        private void Judge()
        {
            var dirtAverage = Average(dirt);
            var moisture = Average(water);
            var streakAverage = Average(streak);
            var elapsed = Time.time - startedAt;
            var cleanliness = Mathf.Clamp01(1f - dirtAverage * 3.1f);
            var dryness = Mathf.Clamp01(1f - moisture * 2.7f);
            var finish = Mathf.Clamp01(1f - streakAverage * 5f);
            var procedure = Mathf.Clamp01(1f - wrongActions / 170f);
            var efficiency = Mathf.Clamp01(1f - Mathf.Max(0, productUsed - 1.35f) * 0.12f);
            var speed = Mathf.Clamp01(1f - Mathf.Max(0, elapsed - 120f) / 180f);
            var score = Mathf.RoundToInt((cleanliness * 0.38f + dryness * 0.15f + finish * 0.19f +
                                          procedure * 0.16f + efficiency * 0.06f + speed * 0.06f) * 10000);
            var stars = score >= 9000 ? 3 : score >= 7500 ? 2 : 1;
            scoreText.text = $"{new string('★', stars)}  {score:N0}";

            var passed = dirtAverage <= 0.03f && moisture <= 0.028f && streakAverage <= 0.025f && score >= 7200;
            if (passed)
            {
                finished = true;
                status.text = $"合格！ 汚れ {dirtAverage * 100:0.0}% / 水筋 {streakAverage * 100:0.0}%";
                var next = Button(status.transform.parent, "次の現場", new Vector2(0.66f, 0.018f), new Vector2(0.795f, 0.095f));
                next.onClick.AddListener(() =>
                {
                    Destroy(next.gameObject);
                    stage++;
                    StartStage();
                });
            }
            else
            {
                var reason = dirtAverage > 0.03f ? "汚れが残っています"
                    : streakAverage > 0.025f ? "スクイジーの水筋が残っています"
                    : moisture > 0.028f ? "水分が残っています"
                    : "手順を見直してください";
                status.text = $"再清掃：{reason}　汚れ {dirtAverage * 100:0.0}% / 水筋 {streakAverage * 100:0.0}%";
            }
        }

        private static float Average(float[] values)
        {
            var total = 0f;
            foreach (var value in values) total += value;
            return total / values.Length;
        }

        private void UpdateTimer()
        {
            if (timerText == null) return;
            timerText.text = $"開店まで　{Mathf.FloorToInt(remainingTime / 60):00}:{Mathf.FloorToInt(remainingTime % 60):00}";
            timerText.color = remainingTime < 30f ? new Color(1f, 0.4f, 0.3f) : Color.white;
        }

        private void RefreshAll()
        {
            for (var i = 0; i < cells.Count; i++) RefreshCell(i);
            scoreText.text = "SCORE　—";
        }

        private void RefreshCell(int i)
        {
            var baseColor = Color.Lerp(new Color(0.18f, 0.34f, 0.40f, 0.04f),
                new Color(0.18f, 0.56f, 0.70f, 0.42f), water[i]);
            var dirtTint = dirtKinds[i] switch
            {
                DirtKind.Mud => new Color(0.30f, 0.19f, 0.09f, 0.86f),
                DirtKind.Oil => new Color(0.32f, 0.36f, 0.34f, 0.72f),
                _ => new Color(0.64f, 0.58f, 0.46f, 0.88f)
            };
            var visibility = Mathf.Clamp01(dirt[i] * (inspectionLight ? 1.35f : 1f));
            var result = Color.Lerp(baseColor, dirtTint, visibility);
            if (streak[i] > 0)
                result = Color.Lerp(result, new Color(0.76f, 0.91f, 0.96f, 0.72f), streak[i]);
            cells[i].color = result;
        }

        private void RefreshButtons()
        {
            foreach (var item in toolButtons)
            {
                var colors = item.Value.colors;
                colors.normalColor = item.Key == selected ? new Color(0.05f, 0.56f, 0.64f) : new Color(0.08f, 0.12f, 0.14f);
                item.Value.colors = colors;
            }
        }

        private void AddToolButton(Transform parent, Tool tool, string title, float y)
        {
            var button = Button(parent, title, new Vector2(0.05f, y), new Vector2(0.95f, y + 0.125f));
            button.onClick.AddListener(() => SelectTool(tool));
            toolButtons.Add(tool, button);
        }

        private static RectTransform PhotoPanel(Transform parent, string name, string resourcePath, Vector2 min, Vector2 max)
        {
            var rect = Panel(parent, name, Color.white, min, max);
            var image = rect.GetComponent<Image>();
            image.sprite = LoadSprite(resourcePath);
            image.preserveAspect = false;
            return rect;
        }

        private static Image ImageElement(Transform parent, string name, Vector2 min, Vector2 max)
        {
            var rect = Panel(parent, name, Color.white, min, max);
            return rect.GetComponent<Image>();
        }

        private static Sprite LoadSprite(string resourcePath)
        {
            var texture = Resources.Load<Texture2D>(resourcePath);
            return texture == null ? null : Sprite.Create(texture,
                new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100f);
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
            var panel = Panel(parent, title, new Color(0.08f, 0.12f, 0.14f), min, max);
            panel.GetComponent<Image>().raycastTarget = true;
            var button = panel.gameObject.AddComponent<Button>();
            var colors = button.colors;
            colors.highlightedColor = new Color(0.10f, 0.62f, 0.69f);
            colors.pressedColor = new Color(0.04f, 0.40f, 0.47f);
            button.colors = colors;
            Label(panel, title, 30, FontStyle.Bold, TextAnchor.MiddleCenter, Vector2.zero, Vector2.one, Color.white);
            return button;
        }
    }
}
